import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/library_aggregates.dart';
import '../entities/song.dart';
import '../entities/song_sort_option.dart';
import '../value_objects/album_id.dart';
import '../value_objects/artist_id.dart';
import '../value_objects/song_id.dart';

abstract interface class SongRepository {
  // --- Indexing & Refresh ---
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  });

  Future<Result<void, Failure>> refresh({
    void Function(int current, int total)? onProgress,
  });

  // --- One-Shot Reads (For Pagination, Search, and Exports) ---
  Future<Result<List<Song>, Failure>> getAllSongs({
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  });

  Future<Result<List<Song>, Failure>> getSongsWindow({
    required int offset,
    required int limit,
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  });

  Future<Result<Song, Failure>> getSongById(SongId id);

  Future<Result<List<Song>, Failure>> searchSongs(
    String query, {
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  });

  Future<Result<List<String>, Failure>> searchArtists(String query);

  Future<Result<List<String>, Failure>> searchAlbums(String query);

  Future<Result<void, Failure>> updateLyricOffset(SongId id, int offsetMs);

  // --- Reactive Streams (For UI Feeds) ---

  Stream<void> get coversUpdatedStream;

  Stream<Result<List<(String, int)>, Failure>> watchAlphabeticalIndex({
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  });

  Stream<Result<List<Album>, Failure>> watchAllAlbums({
    AlbumSortOption sortOption = AlbumSortOption.name,
    bool isAscending = true,
  });

  Stream<Result<List<Artist>, Failure>> watchAllArtists({
    ArtistSortOption sortOption = ArtistSortOption.name,
    bool isAscending = true,
  });

  Stream<Result<List<Genre>, Failure>> watchAllGenres();

  Stream<Result<List<FolderSummary>, Failure>> watchAllFolders();

  Stream<Result<List<Song>, Failure>> watchSongsByArtist(ArtistId artistId);

  Stream<Result<List<Song>, Failure>> watchSongsByAlbum(AlbumId albumId);

  Stream<Result<List<Song>, Failure>> watchSongsByFolder(String folderPath);
}
