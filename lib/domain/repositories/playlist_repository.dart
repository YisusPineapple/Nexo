import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playlist.dart';
import '../entities/song.dart';
import '../value_objects/playlist_id.dart';
import '../value_objects/song_id.dart';

abstract interface class PlaylistRepository {
  Future<Result<List<Playlist>, Failure>> getAllPlaylists();
  Future<Result<Playlist, Failure>> getPlaylistById(PlaylistId id);
  Future<Result<void, Failure>> savePlaylist(Playlist playlist);
  Future<Result<void, Failure>> deletePlaylist(PlaylistId id);
  
  Future<Result<List<Song>, Failure>> getPlaylistSongs(PlaylistId id);
  Future<Result<void, Failure>> addSongToPlaylist(PlaylistId playlistId, SongId songId);
  
  /// Uses [position] instead of [songId] because a playlist can contain
  /// the exact same song multiple times.
  Future<Result<void, Failure>> removeSongFromPlaylist(PlaylistId playlistId, int position);
  Future<Result<void, Failure>> reorderPlaylist(PlaylistId playlistId, int oldIndex, int newIndex);
}