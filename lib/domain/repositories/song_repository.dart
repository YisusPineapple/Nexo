import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/song.dart';
import '../value_objects/album_id.dart';
import '../value_objects/artist_id.dart';
import '../value_objects/song_id.dart';

/// Read/write access to the indexed song library — the ONLY boundary
/// between Domain and the actual filesystem/DB. Per Clean Architecture,
/// no layer above Domain talks to disk or SQLite directly; everything
/// goes through this contract, implemented later in the Data layer
/// (Drift + audio_metadata_reader).
///
/// Deliberately scoped to Song-level operations only. The BIBLIOTECA
/// aggregate views (por Álbum, por Artista, por Género) are NOT modeled
/// here as methods returning dedicated Artist/Album entities — those
/// entities don't exist in Domain yet. Grouping [getAllSongs] results by
/// [Song.trackArtistId] / [Song.albumId] client-side is enough until a
/// future phase actually needs Artist/Album as first-class entities;
/// inventing them now would be guessing at a shape they don't need yet.
///
/// Watch mode (native file watcher, no full re-index per REPRODUCCIÓN's
/// live-update requirement) is intentionally NOT exposed as a Stream
/// yet — [refresh] is the only re-scan trigger for now. A
/// `Stream<LibraryChange> watchChanges()` (or similar) will be added
/// once the actual file-watcher integration is designed, so that event
/// type isn't guessed at here either.
abstract interface class SongRepository {
  /// Recursively scans [directoryPaths] for supported audio files,
  /// extracts metadata, and adds/updates the indexed library.
  /// Idempotent for paths already indexed: existing songs are updated
  /// in place, never duplicated.
  ///
  /// [onProgress], if supplied, is called after each file finishes
  /// processing (indexed or skipped) with how many have been
  /// processed so far and the total found. Optional so callers that
  /// don't care about UI feedback (background [refresh], tests) don't
  /// need to pass one.
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  });

  /// Re-scans every previously indexed directory. Today this is the
  /// user-triggered stand-in for live watch mode (see class docs) —
  /// e.g. called when the app resumes from background.
  Future<Result<void, Failure>> refresh();

  /// All indexed songs, missing or not — [Song.isMissing] tells the
  /// caller which. Deliberately unsorted: BIBLIOTECA's several sort
  /// options (título, artista, álbum, fecha, duración, añadido) are a
  /// Presentation/use-case concern layered on top of one query, not N
  /// separate repository methods.
  Future<Result<List<Song>, Failure>> getAllSongs();

  /// Returns a [NotFoundFailure] if no song with [id] is indexed. This
  /// is an expected, recoverable case — not a bug — since callers can
  /// legitimately hold a stale [SongId] (e.g. a playlist entry whose
  /// file was deleted and dropped on the next scan).
  Future<Result<Song, Failure>> getSongById(SongId id);

  Future<Result<List<Song>, Failure>> getSongsByArtist(ArtistId artistId);

  Future<Result<List<Song>, Failure>> getSongsByAlbum(AlbumId albumId);

  /// Songs whose [Song.filePath] falls under [folderPath] — backs the
  /// "Carpetas" browsing view. Whether this is recursive is left to the
  /// implementation; the contract only promises "songs under this path".
  Future<Result<List<Song>, Failure>> getSongsByFolder(String folderPath);

  /// Case-insensitive match against title/artist/album, backing
  /// BIBLIOTECA's search bar. The 300ms debounce is a Presentation
  /// concern — this method runs un-throttled on every call.
  Future<Result<List<Song>, Failure>> searchSongs(String query);
}
