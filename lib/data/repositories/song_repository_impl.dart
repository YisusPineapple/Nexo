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
  });

  final List<String> directoryPaths;
  final String coverArtCacheDirectory;
  final SendPort sendPort;
}

Future<void> _indexingIsolateEntry(_IndexingIsolateArgs args) async {
  const scanner = AudioFileScanner();
  const metadataReader = SongMetadataReader();

  try {
    final found = <(String, AudioFormat)>[];
    for (final directoryPath in args.directoryPaths) {
      found.addAll(await scanner.scan(directoryPath));
    }

    final total = found.length;
    
    for (var i = 0; i < total; i++) {
      final (path, format) = found[i];
      Song? song;
      
      // RESILIENCIA: Si un archivo está corrupto o no tiene permisos,
      // la excepción se atrapa aquí. El archivo se ignora (song = null)
      // y el escaneo continúa con el siguiente sin abortar el Isolate.
      try {
        song = await _buildSong(
          path,
          format,
          metadataReader: metadataReader,
          coverArtCacheDirectory: args.coverArtCacheDirectory,
        );
      } catch (e) {
        // Archivo corrupto ignorado silenciosamente.
      }
      
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

  final Set<String> _indexedDirectories = {};

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
    return _scanAndPersist(_indexedDirectories.toList());
  }

  Future<Result<void, Failure>> _scanAndPersist(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    final receivePort = ReceivePort();
    final exitPort = ReceivePort();
    final completer = Completer<Result<void, Failure>>();

    final batchSongs = <Song>[];

    Future<void> flushBatch() async {
      if (batchSongs.isEmpty) return;
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
      if (!completer.isCompleted) completer.complete(result);
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

      return await completer.future;
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