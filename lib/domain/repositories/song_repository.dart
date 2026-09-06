import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/library_aggregates.dart';
import '../entities/song.dart';
import '../entities/song_sort_option.dart';
import '../value_objects/album_id.dart';
import '../value_objects/artist_id.dart';
import '../value_objects/song_id.dart';

abstract interface class SongRepository {
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  });

  Future<Result<void, Failure>> refresh({
    void Function(int current, int total)? onProgress,
  });

  Future<Result<List<Song>, Failure>> getAllSongs({
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  });

  Future<Result<List<Album>, Failure>> getAllAlbums({
    AlbumSortOption sortOption = AlbumSortOption.name,
    bool isAscending = true,
  });

  Future<Result<List<Artist>, Failure>> getAllArtists({
    ArtistSortOption sortOption = ArtistSortOption.name,
    bool isAscending = true,
  });

  Future<Result<List<Genre>, Failure>> getAllGenres();

  Future<Result<List<FolderSummary>, Failure>> getAllFolders();

  Future<Result<Song, Failure>> getSongById(SongId id);

  Future<Result<List<Song>, Failure>> getSongsByArtist(ArtistId artistId);

  Future<Result<List<Song>, Failure>> getSongsByAlbum(AlbumId albumId);

  Future<Result<List<Song>, Failure>> getSongsByFolder(String folderPath);

  Future<Result<List<Song>, Failure>> searchSongs(
    String query, {
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  });

  Future<Result<List<String>, Failure>> searchArtists(String query);

  Future<Result<List<String>, Failure>> searchAlbums(String query);

  Future<Result<void, Failure>> updateLyricOffset(SongId id, int offsetMs);

  Stream<void> get coversUpdatedStream;
}
