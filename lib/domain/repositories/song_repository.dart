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

  // --- One-Shot Reads (For Grouped Library, Playlist Import, Exports) ---
  Future<Result<List<Song>, Failure>> getAllSongs({
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

  /// Reactive window over the catalog, sorted by [sortOption] and optionally
  /// filtered by [query] (FTS5). Emits whenever the underlying [songs] table
  /// changes AND the resulting window differs — no deduplication beyond what
  /// SQLite returns. In particular, a content change (e.g. coverArtPath) on a
  /// song inside the window MUST propagate to consumers; do NOT introduce a
  /// `.distinct()` that compares via [Song.==], which only compares by id and
  /// would silence such changes.
  ///
  /// [offset] is 0-based; [limit] is the page size. Both are clamped by the
  /// implementation against the total row count.
  Stream<Result<List<Song>, Failure>> watchSongsWindow({
    required int offset,
    required int limit,
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
    String query = '',
  });

  /// Reactive count of the catalog, optionally filtered by [query] (FTS5).
  /// Used as the `itemCount` for `ListView.builder` in `SongsScreen`.
  Stream<Result<int, Failure>> watchSongsCount({String query = ''});

  /// Reactive alphabetical index, keyed by the pre-computed `section_key`
  /// column. Emits a list of `(letter, firstGlobalIndex)` pairs where
  /// `firstGlobalIndex` is the 0-based offset of the first song in that
  /// section, in cumulative (not per-section) terms. If [query] is non-empty,
  /// only sections that contain FTS5 matches are emitted.
  Stream<Result<List<(String, int)>, Failure>> watchAlphabeticalIndex({
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
    String query = '',
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
