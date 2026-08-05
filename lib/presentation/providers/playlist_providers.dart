import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../../domain/usecases/playlist_usecases.dart';
import '../../domain/value_objects/playlist_id.dart';
import '../../domain/value_objects/song_id.dart';
import 'repository_providers.dart';

final playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final repo = ref.watch(playlistRepositoryProvider);
  final result = await repo.getAllPlaylists();
  return result.when(ok: (playlists) => playlists, err: (e) => throw e);
});

final playlistSongsProvider = FutureProvider.family<List<Song>, String>((ref, playlistId) async {
  final repo = ref.watch(playlistRepositoryProvider);
  final result = await repo.getPlaylistSongs(PlaylistId(playlistId));
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final playlistControllerProvider = Provider<PlaylistController>((ref) {
  return PlaylistController(ref);
});

class PlaylistController {
  PlaylistController(this._ref);
  final Ref _ref;

  Future<void> createPlaylist(String name) async {
    final useCase = CreatePlaylistUseCase(_ref.read(playlistRepositoryProvider));
    final result = await useCase.call(name);
    if (result.isOk) {
      _ref.invalidate(playlistsProvider);
    }
  }

  Future<void> deletePlaylist(String id) async {
    final useCase = DeletePlaylistUseCase(_ref.read(playlistRepositoryProvider));
    final result = await useCase.call(PlaylistId(id));
    if (result.isOk) {
      _ref.invalidate(playlistsProvider);
    }
  }

  Future<void> addSong(String playlistId, String songId) async {
    final useCase = AddSongToPlaylistUseCase(_ref.read(playlistRepositoryProvider));
    final result = await useCase.call((
      playlistId: PlaylistId(playlistId),
      songId: SongId(songId),
    ));
    if (result.isOk) {
      _ref.invalidate(playlistSongsProvider(playlistId));
    }
  }

  Future<void> removeSong(String playlistId, int position) async {
    final useCase = RemoveSongFromPlaylistUseCase(_ref.read(playlistRepositoryProvider));
    final result = await useCase.call((
      playlistId: PlaylistId(playlistId),
      position: position,
    ));
    if (result.isOk) {
      _ref.invalidate(playlistSongsProvider(playlistId));
    }
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final useCase = RenamePlaylistUseCase(_ref.read(playlistRepositoryProvider));
    final result = await useCase.call((
      id: PlaylistId(id),
      newName: newName,
    ));
    if (result.isOk) {
      _ref.invalidate(playlistsProvider);
    }
  }

  Future<String?> exportPlaylist(String id, String exportDirectory) async {
    final useCase = ExportPlaylistUseCase(_ref.read(playlistRepositoryProvider));
    final result = await useCase.call((
      id: PlaylistId(id),
      exportDirectory: exportDirectory,
    ));
    return result.when(ok: (_) => null, err: (e) => e.message);
  }

  Future<String?> importPlaylist(String filePath) async {
    final useCase = ImportPlaylistUseCase(
      _ref.read(playlistRepositoryProvider),
      _ref.read(songRepositoryProvider),
    );
    final result = await useCase.call(filePath);
    if (result.isOk) {
      _ref.invalidate(playlistsProvider);
      return null;
    }
    return result.when(ok: (_) => null, err: (e) => e.message);
  }
}