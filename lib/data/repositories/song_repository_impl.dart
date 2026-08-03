import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/audio_format.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/value_objects/album_id.dart';
import '../../domain/value_objects/artist_id.dart';
import '../../domain/value_objects/song_id.dart';
import '../local/app_database.dart';
import '../local/mappers/song_mapper.dart';
import '../sources/audio_file_scanner.dart';
import '../sources/song_metadata_reader.dart';

/// Real [SongRepository] backed by [AppDatabase] (Drift),
/// [AudioFileScanner] (filesystem), and [SongMetadataReader]
/// (audio_metadata_reader + image).
///
/// The actual scan + metadata-read loop now runs inside a spawned
/// [Isolate.run] — satisfying PARTE A's "todo I/O pesado... en
/// Isolates" requirement, flagged as pending since this file was
/// first written. [AudioFileScanner]/[SongMetadataReader] are no
/// longer constructor-injectable: both are stateless `const` classes
/// with no interface to fake against, and the isolate function builds
/// its own fresh instances rather than capturing this repository's —
/// which would force them to be isolate-transferable for no real gain,
/// since neither holds any state to begin with.
class SongRepositoryImpl implements SongRepository {
  SongRepositoryImpl(
    this._db, {
    required String coverArtCacheDirectory,
    SongMapper mapper = const SongMapper(),
  })  : _coverArtCacheDirectory = coverArtCacheDirectory,
        _mapper = mapper;

  final AppDatabase _db;
  final String _coverArtCacheDirectory;
  final SongMapper _mapper;

  /// Every directory ever passed to [indexDirectories], so [refresh]
  /// can re-scan them without the caller remembering the list itself.
  final List<String> _indexedDirectories = [];

  @override
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths,
  ) async {
    _indexedDirectories.addAll(directoryPaths);
    return _scanAndPersist(directoryPaths);
  }

  @override
  Future<Result<void, Failure>> refresh() {
    return _scanAndPersist(_indexedDirectories);
  }

  Future<Result<void, Failure>> _scanAndPersist(
    List<String> directoryPaths,
  ) async {
    try {
      // Copied to a local BEFORE the closure below — the function
      // passed to Isolate.run must never capture `this` (which holds
      // _db, an AppDatabase/Drift connection that is NOT
      // isolate-transferable), only plain, transferable values like
      // this String.
      final coverArtCacheDirectory = _coverArtCacheDirectory;

      // Everything CPU/file-parsing heavy (audio_metadata_reader's
      // tag parsing, image.decodeImage/copyResize for cover art)
      // happens inside the spawned isolate, off the UI's event loop.
      // DB writes stay on THIS isolate, since they go through the
      // AppDatabase instance this repository already holds — not
      // something to hand into an unrelated second isolate.
      final songs = await Isolate.run(
        () => _scanDirectoriesToSongs(
          directoryPaths,
          coverArtCacheDirectory: coverArtCacheDirectory,
        ),
      );

      for (final song in songs) {
        await _db
            .into(_db.songs)
            .insertOnConflictUpdate(_mapper.toCompanion(song));
      }
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to index directories.', cause: e));
    }
  }

  /// Runs entirely inside the isolate [Isolate.run] spawns — `static`
  /// so it cannot accidentally close over `this`.
  static Future<List<Song>> _scanDirectoriesToSongs(
    List<String> directoryPaths, {
    required String coverArtCacheDirectory,
  }) async {
    const scanner = AudioFileScanner();
    const metadataReader = SongMetadataReader();
    final songs = <Song>[];

    for (final directoryPath in directoryPaths) {
      final found = await scanner.scan(directoryPath);
      for (final (path, format) in found) {
        final song = await _buildSong(
          path,
          format,
          metadataReader: metadataReader,
          coverArtCacheDirectory: coverArtCacheDirectory,
        );
        // A malformed tag can fail Song.create's own validation (e.g.
        // a corrupt duration) — skip that ONE file rather than
        // aborting the whole scan. RESILIENCIA: a bad file must never
        // halt indexing.
        if (song != null) songs.add(song);
      }
    }
    return songs;
  }

  static Future<Song?> _buildSong(
    String path,
    AudioFormat format, {
    required SongMetadataReader metadataReader,
    required String coverArtCacheDirectory,
  }) async {
    final file = File(path);
    final stat = await file.stat();
    final extracted = await metadataReader.read(file);

    final id = SongId(path);
    String? coverArtPath;
    if (extracted.coverArtBytes != null) {
      coverArtPath = await metadataReader.cacheCoverArt(
        coverBytes: extracted.coverArtBytes!,
        cacheDirectory: coverArtCacheDirectory,
        songId: id.value.hashCode.toRadixString(16),
      );
    }

    final songResult = Song.create(
      id: id,
      title: extracted.title ?? p.basenameWithoutExtension(path),
      trackArtistId: ArtistId(extracted.artist ?? 'unknown-artist'),
      albumId: extracted.album == null ? null : AlbumId(extracted.album!),
      trackNumber: extracted.trackNumber,
      discNumber: extracted.discNumber,
      duration: extracted.duration,
      filePath: path,
      format: format,
      fileSizeBytes: stat.size,
      genreNames: extracted.genres,
      year: extracted.year,
      coverArtPath: coverArtPath,
      dateAddedUtc: DateTime.now().toUtc(),
    );

    return songResult.valueOrNull;
  }

  @override
  Future<Result<List<Song>, Failure>> getAllSongs() async {
    return _mapRows(await _db.select(_db.songs).get());
  }

  @override
  Future<Result<Song, Failure>> getSongById(SongId id) async {
    final row = await (_db.select(_db.songs)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    if (row == null) {
      return Err(NotFoundFailure('No song found with id "${id.value}".'));
    }
    return _mapper.toEntity(row);
  }

  @override
  Future<Result<List<Song>, Failure>> getSongsByArtist(
    ArtistId artistId,
  ) async {
    final rows = await (_db.select(_db.songs)
          ..where((t) => t.trackArtistId.equals(artistId.value)))
        .get();
    return _mapRows(rows);
  }

  @override
  Future<Result<List<Song>, Failure>> getSongsByAlbum(AlbumId albumId) async {
    final rows = await (_db.select(_db.songs)
          ..where((t) => t.albumId.equals(albumId.value)))
        .get();
    return _mapRows(rows);
  }

  @override
  Future<Result<List<Song>, Failure>> getSongsByFolder(
    String folderPath,
  ) async {
    final rows = await _db.select(_db.songs).get();
    final matching =
        rows.where((row) => row.filePath.startsWith(folderPath)).toList();
    return _mapRows(matching);
  }

  @override
  Future<Result<List<Song>, Failure>> searchSongs(String query) async {
    final normalized = query.toLowerCase();
    final rows = await _db.select(_db.songs).get();
    final matching = rows.where((row) {
      return row.title.toLowerCase().contains(normalized) ||
          row.trackArtistId.toLowerCase().contains(normalized) ||
          (row.albumId?.toLowerCase().contains(normalized) ?? false);
    }).toList();
    return _mapRows(matching);
  }

  Result<List<Song>, Failure> _mapRows(List<SongRow> rows) {
    final songs = <Song>[];
    for (final row in rows) {
      final result = _mapper.toEntity(row);
      if (result.isErr) {
        return result.when(ok: (_) => const Ok([]), err: Err.new);
      }
      songs.add(result.valueOrNull!);
    }
    return Ok(songs);
  }
}
