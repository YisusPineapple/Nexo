import 'dart:async';
import 'dart:io';
import 'dart:isolate';
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

sealed class _IndexingMessage { const _IndexingMessage(); }
final class _IndexingProgress extends _IndexingMessage {
  const _IndexingProgress(this.current, this.total, this.song);
  final int current; final int total; final Song? song;
}
final class _IndexingDone extends _IndexingMessage { const _IndexingDone(); }
final class _IndexingFailed extends _IndexingMessage {
  const _IndexingFailed(this.message); final String message;
}

class _IndexingIsolateArgs {
  const _IndexingIsolateArgs({
    required this.directoryPaths, required this.coverArtCacheDirectory,
    required this.sendPort, required this.excludedPaths,
  });
  final List<String> directoryPaths; final String coverArtCacheDirectory;
  final SendPort sendPort; final Set<String> excludedPaths;
}

Future<void> _indexingIsolateEntry(_IndexingIsolateArgs args) async {
  const scanner = AudioFileScanner();
  const metadataReader = SongMetadataReader();

  try {
    final foundMap = <String, AudioFormat>{};
    for (final directoryPath in args.directoryPaths) {
      final scanned = await scanner.scan(directoryPath, excludedPaths: args.excludedPaths);
      for (final (path, format) in scanned) {
        foundMap[path] = format; // Deduplicate paths
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
        );
      } catch (_) {}
      args.sendPort.send(_IndexingProgress(i + 1, total, song));
    }
    args.sendPort.send(const _IndexingDone());
  } catch (e) {
    args.sendPort.send(_IndexingFailed(e.toString()));
  }
}

Future<Song?> _buildSong(String path, AudioFormat format, {required SongMetadataReader metadataReader, required String coverArtCacheDirectory}) async {
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

  return Song.create(
    id: id, title: extracted.title ?? p.basenameWithoutExtension(path),
    trackArtistId: ArtistId(extracted.artist ?? 'unknown-artist'),
    albumId: extracted.album == null ? null : AlbumId(extracted.album!),
    trackNumber: extracted.trackNumber, discNumber: extracted.discNumber,
    duration: extracted.duration, filePath: path, format: format,
    fileSizeBytes: stat.size, genreNames: extracted.genres, year: extracted.year,
    coverArtPath: coverArtPath, dateAddedUtc: DateTime.now().toUtc(),
  ).valueOrNull;
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

  @override
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    return _scanAndPersist(directoryPaths, onProgress: onProgress);
  }

  @override
  Future<Result<void, Failure>> refresh() async {
    final foldersResult = await _libraryFolderRepository.getIndexedFolders();
    if (foldersResult.isErr) {
      return Err(foldersResult.when(ok: (_) => throw Exception(), err: (e) => e));
    }
    final paths = foldersResult.valueOrNull!.map((f) => f.path).toList();
    return _scanAndPersist(paths);
  }

  Future<Result<void, Failure>> _scanAndPersist(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    if (_isScanning) {
      return const Ok(null); // Prevent concurrent scan progress collisions
    }
    _isScanning = true;

    final excludedResult = await _libraryFolderRepository.getExcludedFolders();
    final excludedPaths = excludedResult.valueOrNull?.map((e) => e.path).toSet() ?? {};

    final receivePort = ReceivePort();
    final exitPort = ReceivePort();
    final completer = Completer<Result<void, Failure>>();
    final batchSongs = <Song>[];
    bool isDoneReceived = false;

    Future<void> flushBatch() async {
      if (batchSongs.isEmpty) return;
      final toInsert = List<Song>.of(batchSongs);
      batchSongs.clear();
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.songs, toInsert.map((s) => _mapper.toCompanion(s)));
      });
    }

    void finish(Result<void, Failure> result) {
      if (!completer.isCompleted) {
        _isScanning = false;
        completer.complete(result);
      }
    }

    receivePort.listen((rawMessage) async {
      try {
        switch (rawMessage) {
          case _IndexingProgress(:final current, :final total, :final song):
            if (song != null) {
              batchSongs.add(song);
              if (batchSongs.length >= 50) await flushBatch();
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

    // FIX: Only trigger unexpected exit if _IndexingDone was never received
    exitPort.listen((_) {
      if (!isDoneReceived) {
        finish(const Err(UnexpectedFailure('Indexing isolate exited unexpectedly.')));
      }
    });

    try {
      await Isolate.spawn(
        _indexingIsolateEntry,
        _IndexingIsolateArgs(
          directoryPaths: directoryPaths, coverArtCacheDirectory: _coverArtCacheDirectory,
          sendPort: receivePort.sendPort, excludedPaths: excludedPaths,
        ),
        onExit: exitPort.sendPort,
      );
      return await completer.future;
    } catch (e) {
      _isScanning = false;
      return Err(UnexpectedFailure('Failed to index directories.', cause: e));
    } finally {
      receivePort.close();
      exitPort.close();
    }
  }

  @override
  Future<Result<List<Song>, Failure>> getAllSongs() async => _mapRows(await _db.select(_db.songs).get());

  @override
  Future<Result<Song, Failure>> getSongById(SongId id) async {
    final row = await (_db.select(_db.songs)..where((t) => t.id.equals(id.value))).getSingleOrNull();
    if (row == null) return Err(NotFoundFailure('No song found with id "${id.value}".'));
    return _mapper.toEntity(row);
  }

  @override
  Future<Result<List<Song>, Failure>> getSongsByArtist(ArtistId artistId) async =>
      _mapRows(await (_db.select(_db.songs)..where((t) => t.trackArtistId.equals(artistId.value))).get());

  @override
  Future<Result<List<Song>, Failure>> getSongsByAlbum(AlbumId albumId) async =>
      _mapRows(await (_db.select(_db.songs)..where((t) => t.albumId.equals(albumId.value))).get());

  @override
  Future<Result<List<Song>, Failure>> getSongsByFolder(String folderPath) async =>
      _mapRows((await _db.select(_db.songs).get()).where((row) => row.filePath.startsWith(folderPath)).toList());

  @override
  Future<Result<List<Song>, Failure>> searchSongs(String query) async {
    final normalized = query.toLowerCase();
    return _mapRows((await _db.select(_db.songs).get()).where((row) =>
        row.title.toLowerCase().contains(normalized) ||
        row.trackArtistId.toLowerCase().contains(normalized) ||
        (row.albumId?.toLowerCase().contains(normalized) ?? false)).toList());
  }

  Result<List<Song>, Failure> _mapRows(List<SongRow> rows) {
    final songs = <Song>[];
    for (final row in rows) {
      final result = _mapper.toEntity(row);
      if (result.isErr) return result.when(ok: (_) => const Ok([]), err: Err.new);
      songs.add(result.valueOrNull!);
    }
    return Ok(songs);
  }
}