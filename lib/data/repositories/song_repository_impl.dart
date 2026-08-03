import 'dart:async';
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

/// Messages the spawned indexing isolate sends back over its
/// [SendPort] — a small closed hierarchy instead of raw dynamic/Map
/// messages, so the receiving side pattern-matches exhaustively
/// instead of guessing at a message's shape.
sealed class _IndexingMessage {
  const _IndexingMessage();
}

/// Sent after each file finishes processing, found or skipped alike —
/// [current] always advances even for a file that fails
/// [Song.create]'s own validation, so the total never stalls on a bad
/// file (RESILIENCIA).
final class _IndexingProgress extends _IndexingMessage {
  const _IndexingProgress({required this.current, required this.total});
  final int current;
  final int total;
}

final class _IndexingDone extends _IndexingMessage {
  const _IndexingDone(this.songs);
  final List<Song> songs;
}

/// An UNEXPECTED failure that aborted the whole scan — as opposed to
/// a single bad file, which is silently skipped and never reaches
/// this class at all.
final class _IndexingFailed extends _IndexingMessage {
  const _IndexingFailed(this.message);
  final String message;
}

/// Bundles everything [_indexingIsolateEntry] needs — [Isolate.spawn]
/// only accepts a single message argument, so multiple values are
/// bundled into one small transferable class instead of an
/// index-based positional List/Map.
class _IndexingIsolateArgs {
  const _IndexingIsolateArgs({
    required this.directoryPaths,
    required this.coverArtCacheDirectory,
    required this.sendPort,
  });

  final List<String> directoryPaths;
  final String coverArtCacheDirectory;
  final SendPort sendPort;
}

/// Runs entirely inside the isolate [Isolate.spawn] creates — a
/// top-level function, not a class method, since it must not close
/// over any instance state.
Future<void> _indexingIsolateEntry(_IndexingIsolateArgs args) async {
  const scanner = AudioFileScanner();
  const metadataReader = SongMetadataReader();

  try {
    // Scan every directory FIRST to know the true total up front —
    // reporting progress against a total that keeps growing mid-scan
    // would be more confusing than reporting nothing at all.
    final found = <(String, AudioFormat)>[];
    for (final directoryPath in args.directoryPaths) {
      found.addAll(await scanner.scan(directoryPath));
    }

    final total = found.length;
    final songs = <Song>[];
    for (var i = 0; i < total; i++) {
      final (path, format) = found[i];
      final song = await _buildSong(
        path,
        format,
        metadataReader: metadataReader,
        coverArtCacheDirectory: args.coverArtCacheDirectory,
      );
      // A malformed tag can fail Song.create's own validation (e.g. a
      // corrupt duration) — skip that ONE file rather than aborting
      // the whole scan.
      if (song != null) songs.add(song);
      args.sendPort.send(_IndexingProgress(current: i + 1, total: total));
    }

    args.sendPort.send(_IndexingDone(songs));
  } catch (e) {
    args.sendPort.send(_IndexingFailed(e.toString()));
  }
}

Future<Song?> _buildSong(
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

/// Real [SongRepository] backed by [AppDatabase] (Drift),
/// [AudioFileScanner] (filesystem), and [SongMetadataReader]
/// (audio_metadata_reader + image).
///
/// Indexing spawns a dedicated isolate ([Isolate.spawn], not the
/// simpler [Isolate.run]) so it can stream per-file progress back over
/// a [SendPort] as it works. The extra [onExit] port below exists
/// because [Isolate.run] handled isolate-crash reporting for us
/// automatically — dropping to [Isolate.spawn] means re-adding that
/// safety net ourselves, or a genuinely crashed isolate would leave
/// this Future waiting forever instead of completing with a Failure.
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

  final List<String> _indexedDirectories = [];

  @override
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    _indexedDirectories.addAll(directoryPaths);
    return _scanAndPersist(directoryPaths, onProgress: onProgress);
  }

  @override
  Future<Result<void, Failure>> refresh() {
    return _scanAndPersist(_indexedDirectories);
  }

  Future<Result<void, Failure>> _scanAndPersist(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    final receivePort = ReceivePort();
    final exitPort = ReceivePort();
    final completer = Completer<Result<List<Song>, Failure>>();

    void finish(Result<List<Song>, Failure> result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    receivePort.listen((rawMessage) {
      switch (rawMessage) {
        case _IndexingProgress(:final current, :final total):
          onProgress?.call(current, total);
        case _IndexingDone(:final songs):
          finish(Ok(songs));
        case _IndexingFailed(:final message):
          finish(Err(UnexpectedFailure(message)));
      }
    });
    exitPort.listen((_) {
      finish(
        const Err(UnexpectedFailure('Indexing isolate exited unexpectedly.')),
      );
    });

    try {
      final coverArtCacheDirectory = _coverArtCacheDirectory;
      await Isolate.spawn(
        _indexingIsolateEntry,
        _IndexingIsolateArgs(
          directoryPaths: directoryPaths,
          coverArtCacheDirectory: coverArtCacheDirectory,
          sendPort: receivePort.sendPort,
        ),
        onExit: exitPort.sendPort,
      );

      final result = await completer.future;
      return await result.when(
        ok: (songs) async {
          for (final song in songs) {
            await _db
                .into(_db.songs)
                .insertOnConflictUpdate(_mapper.toCompanion(song));
          }
          return const Ok(null);
        },
        err: (failure) async => Err(failure),
      );
    } catch (e) {
      return Err(UnexpectedFailure('Failed to index directories.', cause: e));
    } finally {
      receivePort.close();
      exitPort.close();
    }
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