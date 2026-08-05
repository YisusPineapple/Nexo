import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';
import '../value_objects/playlist_id.dart';
import '../value_objects/song_id.dart';
import 'use_case.dart';

final class CreatePlaylistUseCase implements UseCase<void, String> {
  CreatePlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(String name) async {
    final id = PlaylistId(DateTime.now().millisecondsSinceEpoch.toString());
    final playlistResult = Playlist.create(
      id: id,
      name: name,
      dateCreated: DateTime.now(),
    );

    return playlistResult.asyncAndThen((playlist) => _repository.savePlaylist(playlist));
  }
}

final class DeletePlaylistUseCase implements UseCase<void, PlaylistId> {
  DeletePlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(PlaylistId id) {
    return _repository.deletePlaylist(id);
  }
}

typedef AddSongParams = ({PlaylistId playlistId, SongId songId});

final class AddSongToPlaylistUseCase implements UseCase<void, AddSongParams> {
  AddSongToPlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(AddSongParams params) {
    return _repository.addSongToPlaylist(params.playlistId, params.songId);
  }
}

typedef RemoveSongParams = ({PlaylistId playlistId, int position});

final class RemoveSongFromPlaylistUseCase implements UseCase<void, RemoveSongParams> {
  RemoveSongFromPlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(RemoveSongParams params) {
    return _repository.removeSongFromPlaylist(params.playlistId, params.position);
  }
}