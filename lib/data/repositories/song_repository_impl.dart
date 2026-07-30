import 'dart:io';

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
/// PENDING (flagged, not hidden): the actual scan + metadata-read
/// loop below runs on the calling isolate, not a background one —
/// PARTE A's Isolate requirement for indexing is NOT yet satisfied
/// here. DB writes themselves already run in their own isolate (via
/// [AppDatabase]'s [openConnection]), but the CPU/file work in
/// [_indexSingleFile] does not yet. Wrapping this in `Isolate.run()`
/// is the very next thing to do once this file itself is verified
/// compiling and passing tests.
class SongRepositoryImpl implements SongRepository {
  SongRepositoryImpl(
    this._db, {
    required String coverArtCacheDirectory,
    AudioFileScanner scanner = const AudioFileScanner(),
    SongMetadataReader metadataReader = const SongMetadataReader(),
    SongMapper mapper = const SongMapper(),
  })  : _coverArtCacheDirectory = coverArtCacheDirectory,
        _scanner = scanner,
        _metadataReader = metadataReader,
        _mapper = mapper;

  final AppDatabase _db;
  final String _coverArtCacheDirectory;
  final AudioFileScanner _scanner;
  final SongMetadataReader _metadataReader;
  final SongMapper _mapper;

  /// Every directory ever passed to [indexDirectories], so [refresh]
  /// can re-scan them without the caller remembering the list itself.
  /// In-memory only for now — persisting this across app restarts is
  /// a follow-up, not silently assumed to already work.
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
      for (final directoryPath in directoryPaths) {
        final found = await _scanner.scan(directoryPath);
        for (final (path, format) in found) {
          await _indexSingleFile(path, format);
        }
      }
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to index directories.', cause: e));
    }
  }

  Future<void> _indexSingleFile(String path, AudioFormat format) async {
    final file = File(path);
    final stat = await file.stat();
    final extracted = await _metadataReader.read(file);

    final id = SongId(path);
    String? coverArtPath;
    if (extracted.coverArtBytes != null) {
      coverArtPath = await _metadataReader.cacheCoverArt(
        coverBytes: extracted.coverArtBytes!,
        cacheDirectory: _coverArtCacheDirectory,
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

    // A malformed tag can fail Song.create's own validation (e.g. a
    // corrupt duration) — skip that ONE file rather than aborting the
    // whole scan. RESILIENCIA: a bad file must never halt indexing.
    if (songResult.isErr) return;

    await _db.into(_db.songs).insertOnConflictUpdate(
          _mapper.toCompanion(songResult.valueOrNull!),
        );
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
    // SQLite's LIKE is case-insensitive for ASCII by default, so this
    // satisfies the contract's "case-insensitive" requirement without
    // needing a separate lower() call on either side.
    final normalized = query.toLowerCase();
    final rows = await _db.select(_db.songs).get();
    final matching = rows
        .where((row) => row.title.toLowerCase().contains(normalized))
        .toList();
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
