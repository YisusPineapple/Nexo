import 'package:drift/drift.dart';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/value_objects/playlist_id.dart';
import '../../domain/value_objects/song_id.dart';
import '../local/app_database.dart';
import '../local/mappers/playlist_mapper.dart';
import '../local/mappers/song_mapper.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl(
    this._db, {
    PlaylistMapper playlistMapper = const PlaylistMapper(),
    SongMapper songMapper = const SongMapper(),
  })  : _playlistMapper = playlistMapper,
        _songMapper = songMapper;

  final AppDatabase _db;
  final PlaylistMapper _playlistMapper;
  final SongMapper _songMapper;

  @override
  Future<Result<List<Playlist>, Failure>> getAllPlaylists() async {
    try {
      final rows = await (_db.select(_db.playlists)
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();
      final playlists = <Playlist>[];
      for (final row in rows) {
        final result = _playlistMapper.toEntity(row);
        if (result.isOk) playlists.add(result.valueOrNull!);
      }
      return Ok(playlists);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch playlists', cause: e));
    }
  }

  @override
  Future<Result<Playlist, Failure>> getPlaylistById(PlaylistId id) async {
    try {
      final row = await (_db.select(_db.playlists)
            ..where((t) => t.id.equals(id.value)))
          .getSingleOrNull();
      if (row == null) {
        return Err(NotFoundFailure('Playlist not found.'));
      }
      return _playlistMapper.toEntity(row);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch playlist', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> savePlaylist(Playlist playlist) async {
    try {
      await _db
          .into(_db.playlists)
          .insertOnConflictUpdate(_playlistMapper.toCompanion(playlist));
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to save playlist', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> deletePlaylist(PlaylistId id) async {
    try {
      await _db.transaction(() async {
        await (_db.delete(_db.playlistSongs)
              ..where((t) => t.playlistId.equals(id.value)))
            .go();
        await (_db.delete(_db.playlists)..where((t) => t.id.equals(id.value)))
            .go();
      });
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to delete playlist', cause: e));
    }
  }

  @override
  Future<Result<List<Song>, Failure>> getPlaylistSongs(PlaylistId id) async {
    try {
      final refs = await (_db.select(_db.playlistSongs)
            ..where((t) => t.playlistId.equals(id.value))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

      if (refs.isEmpty) return const Ok([]);

      final songIds = refs.map((r) => r.songId).toList();
      final songRows =
          await (_db.select(_db.songs)..where((t) => t.id.isIn(songIds))).get();
      final songMap = {for (final row in songRows) row.id: row};

      final songs = <Song>[];
      for (final ref in refs) {
        final row = songMap[ref.songId];
        if (row != null) {
          final songResult = _songMapper.toEntity(row);
          if (songResult.isOk) songs.add(songResult.valueOrNull!);
        }
      }
      return Ok(songs);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch playlist songs', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> addSongToPlaylist(
    PlaylistId playlistId,
    SongId songId,
  ) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.select(_db.playlistSongs)
              ..where((t) => t.playlistId.equals(playlistId.value)))
            .get()
            .then((rows) => rows.length);
        await _db.into(_db.playlistSongs).insert(
              PlaylistSongsCompanion.insert(
                playlistId: playlistId.value,
                position: count,
                songId: songId.value,
              ),
            );
      });
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to add song to playlist', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> removeSongFromPlaylist(
    PlaylistId playlistId,
    int position,
  ) async {
    try {
      await _db.transaction(() async {
        await (_db.delete(_db.playlistSongs)
              ..where((t) =>
                  t.playlistId.equals(playlistId.value) &
                  t.position.equals(position)))
            .go();

        // Re-normalize positions
        final remaining = await (_db.select(_db.playlistSongs)
              ..where((t) => t.playlistId.equals(playlistId.value))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();

        for (var i = 0; i < remaining.length; i++) {
          if (remaining[i].position != i) {
            await (_db.update(_db.playlistSongs)
                  ..where((t) =>
                      t.playlistId.equals(playlistId.value) &
                      t.position.equals(remaining[i].position)))
                .write(PlaylistSongsCompanion(position: Value(i)));
          }
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to remove song', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> reorderPlaylist(
    PlaylistId playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await _db.transaction(() async {
        final refs = await (_db.select(_db.playlistSongs)
              ..where((t) => t.playlistId.equals(playlistId.value))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();

        if (oldIndex < 0 ||
            oldIndex >= refs.length ||
            newIndex < 0 ||
            newIndex >= refs.length) {
          throw Exception('Invalid indices');
        }

        final item = refs.removeAt(oldIndex);
        refs.insert(newIndex, item);

        await (_db.delete(_db.playlistSongs)
              ..where((t) => t.playlistId.equals(playlistId.value)))
            .go();

        await _db.batch((batch) {
          for (var i = 0; i < refs.length; i++) {
            batch.insert(
              _db.playlistSongs,
              PlaylistSongsCompanion.insert(
                playlistId: playlistId.value,
                position: i,
                songId: refs[i].songId,
              ),
            );
          }
        });
      });
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to reorder playlist', cause: e));
    }
  }
}
