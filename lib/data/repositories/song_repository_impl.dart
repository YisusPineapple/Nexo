import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/audio_format.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/library_folder_repository.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/value_objects/album_id.dart';
import '../../domain/value_objects/artist_id.dart';
import '../../domain/value_objects/song_id.dart';
import '../local/app_database.dart';
import '../local/mappers/song_mapper.dart';
import '../sources/audio_file_scanner.dart';
import '../sources/song_metadata_reader.dart';

sealed class _IndexingMessage {
  const _IndexingMessage();
}

final class _IndexingProgress extends _IndexingMessage {
  const _IndexingProgress(this.current, this.total, this.song);
  final int current;
  final int total;
  final Song? song;
}

final class _IndexingDone extends _IndexingMessage {
  const _IndexingDone();
}

final class _IndexingFailed extends _IndexingMessage {
  const _IndexingFailed(this.message);
  final String message;
}

class _IndexingIsolateArgs {
  const _IndexingIsolateArgs({
    required this.directoryPaths,
    required this.coverArtCacheDirectory,
    required this.sendPort,
    required this.excludedPaths,
  });
  final List<String> directoryPaths;
  final String coverArtCacheDirectory;
  final SendPort sendPort;
  final Set<String> excludedPaths;
}

Future<void> _indexingIsolateEntry(_IndexingIsolateArgs args) async {
  const scanner = AudioFileScanner();
  const metadataReader = SongMetadataReader();

  try {
    final foundMap = <String, AudioFormat>{};
    for (final directoryPath in args.directoryPaths) {
      final scanned = await scanner.scan(
        directoryPath,
        excludedPaths: args.excludedPaths,
      );
      for (final (path, format) in scanned) {
        foundMap[path] = format;
      }
    }

    final entries = foundMap.entries.toList();
    final total = entries.length;

    for (var i = 0; i < total; i++) {
      final path = entries[i].key;
      final format = entries[i].value;
      Song? song;
      try {
        song = await _buildSong(
          path,
          format,
          metadataReader: metadataReader,
          coverArtCacheDirectory: args.coverArtCacheDirectory,
          extractCover: false,
        );
      } catch (_) {}
      args.sendPort.send(_IndexingProgress(i + 1, total, song));
    }
    args.sendPort.send(const _IndexingDone());
  } catch (e) {
    args.sendPort.send(_IndexingFailed(e.toString()));
  }
}

Future<Song?> _buildSong(
  String path,
  AudioFormat format, {
  required SongMetadataReader metadataReader,
  required String coverArtCacheDirectory,
  required bool extractCover,
}) async {
  final file = File(path);
  final stat = await file.stat();
  final id = SongId(path);

  String title = p.basenameWithoutExtension(path);
  String artist = 'Unknown Artist';
  String? album;
  int? trackNumber;
  int? discNumber;
  Duration duration = Duration.zero;
  List<String> genres = const [];
  int? year;
  String? coverArtPath;
  double? replayGainTrackDb;
  double? replayGainAlbumDb;

  try {
    final extracted =
        await metadataReader.read(file, extractCover: extractCover);
    title = extracted.title ?? title;
    artist = extracted.artist ?? artist;
    album = extracted.album;
    trackNumber = extracted.trackNumber;
    discNumber = extracted.discNumber;
    duration = extracted.duration;
    genres = extracted.genres;
    year = extracted.year;

    replayGainTrackDb = extracted.replayGainTrackDb;
    replayGainAlbumDb = extracted.replayGainAlbumDb;

    if (extractCover && extracted.coverArtBytes != null) {
      final coverHash =
          '${album ?? 'unknown'}_${extracted.albumArtist ?? artist}'
              .hashCode
              .toRadixString(16);
      coverArtPath = await metadataReader.cacheCoverArt(
        coverBytes: extracted.coverArtBytes!,
        cacheDirectory: coverArtCacheDirectory,
        coverId: coverHash,
      );
    }
  } catch (e) {
    debugPrint('Metadata read failed for $path: $e');
  }

  return Song.create(
    id: id,
    title: title,
    trackArtistId: ArtistId(artist),
    albumId: album == null ? null : AlbumId(album),
    trackNumber: trackNumber,
    discNumber: discNumber,
    duration: duration,
    filePath: path,
    format: format,
    fileSizeBytes: stat.size,
    genreNames: genres,
    year: year,
    coverArtPath: coverArtPath,
    replayGainTrackDb: replayGainTrackDb,
    replayGainAlbumDb: replayGainAlbumDb,
    dateAddedUtc: DateTime.now().toUtc(),
    hasNoCover: false,
  ).valueOrNull;
}

class _CoverExtractionArgs {
  const _CoverExtractionArgs({
    required this.songs,
    required this.coverArtCacheDirectory,
    required this.sendPort,
  });
  final List<Song> songs;
  final String coverArtCacheDirectory;
  final SendPort sendPort;
}

Future<void> _coverExtractionIsolateEntry(_CoverExtractionArgs args) async {
  const metadataReader = SongMetadataReader();
  for (final song in args.songs) {
    try {
      final file = File(song.filePath);
      if (!file.existsSync()) {
        continue;
      }

      final extracted = await metadataReader.read(file, extractCover: true);
      if (extracted.coverArtBytes != null) {
        final coverHash =
            '${song.albumId?.value ?? 'unknown'}_${song.albumArtistId?.value ?? song.trackArtistId.value}'
                .hashCode
                .toRadixString(16);
        final path = await metadataReader.cacheCoverArt(
          coverBytes: extracted.coverArtBytes!,
          cacheDirectory: args.coverArtCacheDirectory,
          coverId: coverHash,
        );
        args.sendPort.send({'id': song.id.value, 'path': path});
      } else {
        args.sendPort.send({'id': song.id.value, 'path': null});
      }
    } catch (e) {
      args.sendPort.send({'id': song.id.value, 'path': null});
    }
  }
  args.sendPort.send('DONE');
}

class SongRepositoryImpl implements SongRepository {
  SongRepositoryImpl(
    this._db, {
    required String coverArtCacheDirectory,
    required LibraryFolderRepository libraryFolderRepository,
    SongMapper mapper = const SongMapper(),
  })  : _coverArtCacheDirectory = coverArtCacheDirectory,
        _libraryFolderRepository = libraryFolderRepository,
        _mapper = mapper;

  final AppDatabase _db;
  final String _coverArtCacheDirectory;
  final LibraryFolderRepository _libraryFolderRepository;
  final SongMapper _mapper;
  bool _isScanning = false;
  bool _isExtractingCovers = false;

  /// Safety cap on FTS5 results. Full result pagination through the
  /// Presentation layer is Sprint 6 Task 2 — this constant only
  /// prevents a pathological query (e.g. a single common letter) from
  /// materializing thousands of rows in one shot in the meantime.
  static const int _maxSearchResults = 500;

  final StreamController<void> _coversUpdatedController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get coversUpdatedStream => _coversUpdatedController.stream;

  @override
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    return _scanAndPersist(directoryPaths, onProgress: onProgress);
  }

  @override
  Future<Result<void, Failure>> refresh({
    void Function(int current, int total)? onProgress,
  }) async {
    final foldersResult = await _libraryFolderRepository.getIndexedFolders();
    if (foldersResult.isErr) {
      return Err(
        foldersResult.when(ok: (_) => throw Exception(), err: (e) => e),
      );
    }
    final paths = foldersResult.valueOrNull!.map((f) => f.path).toList();
    return _scanAndPersist(paths, onProgress: onProgress);
  }

  Future<Result<void, Failure>> _scanAndPersist(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    if (_isScanning) {
      return const Err(
          ValidationFailure('A scan is already in progress. Please wait.'));
    }
    _isScanning = true;

    final excludedResult = await _libraryFolderRepository.getExcludedFolders();
    final excludedPaths =
        excludedResult.valueOrNull?.map((e) => e.path).toSet() ?? {};

    final receivePort = ReceivePort();
    final exitPort = ReceivePort();
    final completer = Completer<Result<void, Failure>>();
    final batchSongs = <Song>[];
    bool isDoneReceived = false;

    Future<void> flushBatch() async {
      if (batchSongs.isEmpty) {
        return;
      }
      final toInsert = List<Song>.of(batchSongs);
      batchSongs.clear();
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _db.songs,
          toInsert.map((s) => _mapper.toCompanion(s)),
        );
      });
    }

    void finish(Result<void, Failure> result) {
      if (!completer.isCompleted) {
        _isScanning = false;
        completer.complete(result);
        if (result.isOk) {
          _startBackgroundCoverExtraction();
        }
      }
    }

    receivePort.listen((rawMessage) async {
      try {
        switch (rawMessage) {
          case _IndexingProgress(:final current, :final total, :final song):
            if (song != null) {
              batchSongs.add(song);
              if (batchSongs.length >= 50) {
                await flushBatch();
              }
            }
            onProgress?.call(current, total);
          case _IndexingDone():
            isDoneReceived = true;
            await flushBatch();
            finish(const Ok(null));
          case _IndexingFailed(:final message):
            finish(Err(UnexpectedFailure(message)));
        }
      } catch (e) {
        finish(Err(UnexpectedFailure('Database error during indexing: $e')));
      }
    });

    exitPort.listen((_) {
      if (!isDoneReceived) {
        finish(
          const Err(
            UnexpectedFailure('Indexing isolate exited unexpectedly.'),
          ),
        );
      }
    });

    try {
      await Isolate.spawn(
        _indexingIsolateEntry,
        _IndexingIsolateArgs(
          directoryPaths: directoryPaths,
          coverArtCacheDirectory: _coverArtCacheDirectory,
          sendPort: receivePort.sendPort,
          excludedPaths: excludedPaths,
        ),
        onExit: exitPort.sendPort,
      );
      return await completer.future;
    } catch (e) {
      _isScanning = false;
      return Err(UnexpectedFailure('Failed to index directories.', cause: e));
    }
  }

  Future<void> _startBackgroundCoverExtraction() async {
    if (_isExtractingCovers) {
      return;
    }

    final songsWithoutCover = await (_db.select(_db.songs)
          ..where((t) => t.coverArtPath.isNull() & t.hasNoCover.equals(false)))
        .get();

    if (songsWithoutCover.isEmpty) {
      return;
    }

    _isExtractingCovers = true;
    final receivePort = ReceivePort();
    var updateBatchCount = 0;

    try {
      await Isolate.spawn(
        _coverExtractionIsolateEntry,
        _CoverExtractionArgs(
          songs: songsWithoutCover
              .map((r) => _mapper.toEntity(r).valueOrNull!)
              .toList(),
          coverArtCacheDirectory: _coverArtCacheDirectory,
          sendPort: receivePort.sendPort,
        ),
      );

      receivePort.listen((message) async {
        if (message is Map<String, dynamic>) {
          final id = message['id'] as String;
          final path = message['path'] as String?;

          await (_db.update(_db.songs)..where((t) => t.id.equals(id))).write(
            SongsCompanion(
              coverArtPath: Value(path),
              hasNoCover: Value(path == null),
            ),
          );

          updateBatchCount++;
          // Notify UI every 15 covers extracted so images pop in smoothly
          if (updateBatchCount >= 15) {
            updateBatchCount = 0;
            _coversUpdatedController.add(null);
          }
        } else if (message == 'DONE') {
          _isExtractingCovers = false;
          _coversUpdatedController.add(null);
          receivePort.close();
        }
      });
    } catch (e) {
      _isExtractingCovers = false;
      receivePort.close();
      debugPrint('Failed to start background cover extraction: $e');
    }
  }

  @override
  Future<Result<List<Song>, Failure>> getAllSongs() async =>
      _mapRows(await _db.select(_db.songs).get());

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
          ArtistId artistId) async =>
      _mapRows(
        await (_db.select(_db.songs)
              ..where((t) => t.trackArtistId.equals(artistId.value)))
            .get(),
      );

  @override
  Future<Result<List<Song>, Failure>> getSongsByAlbum(AlbumId albumId) async =>
      _mapRows(
        await (_db.select(_db.songs)
              ..where((t) => t.albumId.equals(albumId.value)))
            .get(),
      );

  @override
  Future<Result<List<Song>, Failure>> getSongsByFolder(
    String folderPath,
  ) async {
    final likePattern = '${_escapeLikePattern(folderPath)}%';
    final rows = await _db
        .customSelect(
          "SELECT * FROM songs WHERE file_path LIKE ? ESCAPE '\\' "
          'ORDER BY file_path',
          variables: [Variable.withString(likePattern)],
          readsFrom: {_db.songs},
        )
        .map((row) => _db.songs.map(row.data))
        .get();
    return _mapRows(rows);
  }

  @override
  Future<Result<List<Song>, Failure>> searchSongs(String query) async {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (terms.isEmpty) return const Ok([]);

    // FIX: Removed the 'f' alias from the MATCH operator to ensure compatibility
    // across all SQLite FTS5 versions.
    final ftsQuery = terms.map((t) => '"${_escapeFts5Term(t)}"*').join(' ');

    final rows = await _db
        .customSelect(
          'SELECT s.* FROM songs s '
          'JOIN songs_fts ON songs_fts.rowid = s.rowid '
          'WHERE songs_fts MATCH ? '
          'ORDER BY rank '
          'LIMIT ?',
          variables: [
            Variable.withString(ftsQuery),
            Variable.withInt(_maxSearchResults),
          ],
          readsFrom: {_db.songs},
        )
        .map((row) => _db.songs.map(row.data))
        .get();

    return _mapRows(rows);
  }

  @override
  Future<Result<void, Failure>> updateLyricOffset(
    SongId id,
    int offsetMs,
  ) async {
    try {
      await (_db.update(_db.songs)..where((t) => t.id.equals(id.value)))
          .write(SongsCompanion(lyricOffsetMs: Value(offsetMs)));
      return const Ok(null);
    } catch (e) {
      return Err(
        UnexpectedFailure('Failed to update lyric offset.', cause: e),
      );
    }
  }

  /// Escapes a token for safe use inside a double-quoted FTS5 string
  /// literal (doubling embedded `"` characters, per FTS5 syntax).
  String _escapeFts5Term(String term) => term.replaceAll('"', '""');

  /// Escapes `\`, `%` and `_` so a folder path can be used as a LIKE
  /// prefix pattern without its own characters being read as wildcards.
  String _escapeLikePattern(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
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
