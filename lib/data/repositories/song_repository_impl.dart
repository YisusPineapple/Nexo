import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../core/error/failures.dart';
import '../../core/utils/artist_splitter.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/audio_format.dart';
import '../../domain/entities/library_aggregates.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/song_sort_option.dart';
import '../../domain/repositories/library_folder_repository.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/value_objects/album_id.dart';
import '../../domain/value_objects/artist_id.dart';
import '../../domain/value_objects/song_id.dart';
import '../local/app_database.dart';
import '../local/converters/string_list_converter.dart';
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

// --- Isolate Grouping Functions ---

typedef _ArtistIsolateArgs = ({
  List<(String trackArtistId, String? albumId, String? coverArtPath)> data,
  ArtistSortOption sortOption,
  bool isAscending,
});

List<Artist> _computeArtists(_ArtistIsolateArgs args) {
  final map = <String,
      ({
    String displayName,
    int songCount,
    Set<String> albums,
    int collabCount,
    String? coverArtPath
  })>{};

  for (final row in args.data) {
    final trackArtistId = row.$1;
    final albumId = row.$2;
    final coverArtPath = row.$3;

    final individuals = splitArtists(trackArtistId);
    final isCollab = individuals.length > 1;

    for (final artist in individuals) {
      final key = normalizeArtist(artist);
      if (key.isEmpty) continue;

      if (!map.containsKey(key)) {
        map[key] = (
          displayName: artist,
          songCount: 0,
          albums: <String>{},
          collabCount: 0,
          coverArtPath: null
        );
      }
      final entry = map[key]!;
      final updatedAlbums = entry.albums.toSet();
      if (albumId != null) updatedAlbums.add(albumId);

      map[key] = (
        displayName: entry.displayName,
        songCount: entry.songCount + 1,
        albums: updatedAlbums,
        collabCount: entry.collabCount + (isCollab ? 1 : 0),
        coverArtPath: entry.coverArtPath ?? coverArtPath,
      );
    }
  }

  final list = map.values
      .map((e) => Artist(
            name: e.displayName,
            songCount: e.songCount,
            albumCount: e.albums.where((a) => a.isNotEmpty).length,
            collaborationCount: e.collabCount,
            coverArtPath: e.coverArtPath,
          ))
      .toList();

  list.sort((a, b) {
    int res;
    switch (args.sortOption) {
      case ArtistSortOption.name:
        res = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        break;
      case ArtistSortOption.songCount:
        res = a.songCount.compareTo(b.songCount);
        break;
      case ArtistSortOption.albumCount:
        res = a.albumCount.compareTo(b.albumCount);
        break;
    }
    return args.isAscending ? res : -res;
  });
  return list;
}

List<Genre> _computeGenres(List<String> rawGenresList) {
  final map = <String, int>{};
  const converter = StringListConverter();

  for (final genreString in rawGenresList) {
    final genres = converter.fromSql(genreString);
    for (final genre in genres) {
      map[genre] = (map[genre] ?? 0) + 1;
    }
  }

  final list =
      map.entries.map((e) => Genre(name: e.key, songCount: e.value)).toList();
  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

List<FolderSummary> _computeFolders(List<String> filePaths) {
  final map = <String, int>{};
  for (final path in filePaths) {
    final dir = p.dirname(path);
    map[dir] = (map[dir] ?? 0) + 1;
  }

  final list = map.entries
      .map((e) => FolderSummary(
          path: e.key, name: p.basename(e.key), songCount: e.value))
      .toList();

  list.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
  return list;
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
  Future<Result<List<Song>, Failure>> getAllSongs({
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  }) async {
    try {
      final query = _db.select(_db.songs)
        ..orderBy([_buildOrderClause(sortOption, isAscending)]);
      return _mapRows(await query.get());
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch all songs.', cause: e));
    }
  }

  @override
  Future<Result<List<Album>, Failure>> getAllAlbums({
    AlbumSortOption sortOption = AlbumSortOption.name,
    bool isAscending = true,
  }) async {
    try {
      final orderCol = switch (sortOption) {
        AlbumSortOption.name => 'LOWER(album_id)',
        AlbumSortOption.artist => 'LOWER(artist)',
        AlbumSortOption.songCount => 'song_count',
      };
      final orderDir = isAscending ? 'ASC' : 'DESC';

      final rows = await _db.customSelect(
        'SELECT album_id, COALESCE(album_artist_id, track_artist_id) AS artist, '
        'MAX(cover_art_path) AS cover_art_path, COUNT(*) AS song_count '
        'FROM songs WHERE album_id IS NOT NULL '
        'GROUP BY album_id ORDER BY $orderCol $orderDir',
        readsFrom: {_db.songs},
      ).get();

      final albums = rows
          .map((r) => Album(
                id: r.read<String>('album_id'),
                name: r.read<String>('album_id'),
                artist: r.read<String>('artist'),
                songCount: r.read<int>('song_count'),
                coverArtPath: r.read<String?>('cover_art_path'),
              ))
          .toList();

      return Ok(albums);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch albums.', cause: e));
    }
  }

  @override
  Future<Result<List<Artist>, Failure>> getAllArtists({
    ArtistSortOption sortOption = ArtistSortOption.name,
    bool isAscending = true,
  }) async {
    try {
      final rows = await _db.customSelect(
        'SELECT track_artist_id, album_id, cover_art_path FROM songs',
        readsFrom: {_db.songs},
      ).get();

      final data = rows
          .map((r) => (
                r.read<String>('track_artist_id'),
                r.read<String?>('album_id'),
                r.read<String?>('cover_art_path'),
              ))
          .toList();

      final artists = await Isolate.run(() => _computeArtists((
            data: data,
            sortOption: sortOption,
            isAscending: isAscending,
          )));

      return Ok(artists);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch artists.', cause: e));
    }
  }

  @override
  Future<Result<List<Genre>, Failure>> getAllGenres() async {
    try {
      final rows = await _db.customSelect(
        'SELECT genre_names FROM songs',
        readsFrom: {_db.songs},
      ).get();

      final data = rows.map((r) => r.read<String>('genre_names')).toList();
      final genres = await Isolate.run(() => _computeGenres(data));

      return Ok(genres);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch genres.', cause: e));
    }
  }

  @override
  Future<Result<List<FolderSummary>, Failure>> getAllFolders() async {
    try {
      final rows = await _db.customSelect(
        'SELECT file_path FROM songs',
        readsFrom: {_db.songs},
      ).get();

      final data = rows.map((r) => r.read<String>('file_path')).toList();
      final folders = await Isolate.run(() => _computeFolders(data));

      return Ok(folders);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch folders.', cause: e));
    }
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
  Future<Result<List<Song>, Failure>> searchSongs(
    String query, {
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  }) async {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (terms.isEmpty) return const Ok([]);

    final ftsQuery = terms.map((t) => '"${_escapeFts5Term(t)}"*').join(' ');

    final orderColumn = switch (sortOption) {
      SongSortOption.title => 'LOWER(s.title)',
      SongSortOption.artist => 'LOWER(s.track_artist_id)',
      SongSortOption.album => 'LOWER(s.album_id)',
      SongSortOption.year => 's.year',
      SongSortOption.duration => 's.duration_ms',
      SongSortOption.dateAdded => 's.date_added_utc_ms',
    };
    final orderDir = isAscending ? 'ASC' : 'DESC';

    try {
      final rows = await _db
          .customSelect(
            'SELECT s.* FROM songs s '
            'JOIN songs_fts ON songs_fts.rowid = s.rowid '
            'WHERE songs_fts MATCH ? '
            'ORDER BY $orderColumn $orderDir '
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
    } catch (e) {
      return Err(UnexpectedFailure('Failed to search songs.', cause: e));
    }
  }

  @override
  Future<Result<List<String>, Failure>> searchArtists(String query) async {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (terms.isEmpty) return const Ok([]);
    final ftsQuery = terms.map((t) => '"${_escapeFts5Term(t)}"*').join(' ');

    try {
      final rows = await _db.customSelect(
        'SELECT DISTINCT s.track_artist_id FROM songs s '
        'JOIN songs_fts ON songs_fts.rowid = s.rowid '
        'WHERE songs_fts MATCH ? '
        'LIMIT 10',
        variables: [Variable.withString(ftsQuery)],
        readsFrom: {_db.songs},
      ).get();

      return Ok(rows.map((r) => r.read<String>('track_artist_id')).toList());
    } catch (e) {
      return Err(UnexpectedFailure('Failed to search artists.', cause: e));
    }
  }

  @override
  Future<Result<List<String>, Failure>> searchAlbums(String query) async {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (terms.isEmpty) return const Ok([]);
    final ftsQuery = terms.map((t) => '"${_escapeFts5Term(t)}"*').join(' ');

    try {
      final rows = await _db.customSelect(
        'SELECT DISTINCT s.album_id FROM songs s '
        'JOIN songs_fts ON songs_fts.rowid = s.rowid '
        'WHERE songs_fts MATCH ? AND s.album_id IS NOT NULL '
        'LIMIT 10',
        variables: [Variable.withString(ftsQuery)],
        readsFrom: {_db.songs},
      ).get();

      return Ok(rows.map((r) => r.read<String>('album_id')).toList());
    } catch (e) {
      return Err(UnexpectedFailure('Failed to search albums.', cause: e));
    }
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

  OrderingTerm Function($SongsTable) _buildOrderClause(
      SongSortOption option, bool isAscending) {
    final mode = isAscending ? OrderingMode.asc : OrderingMode.desc;
    return (t) {
      switch (option) {
        case SongSortOption.title:
          return OrderingTerm(expression: t.title.lower(), mode: mode);
        case SongSortOption.artist:
          return OrderingTerm(expression: t.trackArtistId.lower(), mode: mode);
        case SongSortOption.album:
          return OrderingTerm(expression: t.albumId.lower(), mode: mode);
        case SongSortOption.year:
          return OrderingTerm(expression: t.year, mode: mode);
        case SongSortOption.duration:
          return OrderingTerm(expression: t.durationMs, mode: mode);
        case SongSortOption.dateAdded:
          return OrderingTerm(expression: t.dateAddedUtcMs, mode: mode);
      }
    };
  }

  String _escapeFts5Term(String term) => term.replaceAll('"', '""');

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
