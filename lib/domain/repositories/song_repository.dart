import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/song.dart';
import '../value_objects/album_id.dart';
import '../value_objects/artist_id.dart';
import '../value_objects/song_id.dart';

abstract interface class SongRepository {
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  });

  Future<Result<void, Failure>> refresh();

  Future<Result<List<Song>, Failure>> getAllSongs();

  Future<Result<Song, Failure>> getSongById(SongId id);

  Future<Result<List<Song>, Failure>> getSongsByArtist(ArtistId artistId);

  Future<Result<List<Song>, Failure>> getSongsByAlbum(AlbumId albumId);

  Future<Result<List<Song>, Failure>> getSongsByFolder(String folderPath);

  Future<Result<List<Song>, Failure>> searchSongs(String query);

  /// Updates the saved lyric offset for a specific song.
  Future<Result<void, Failure>> updateLyricOffset(SongId id, int offsetMs);
}