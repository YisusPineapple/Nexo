import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/song.dart';
import '../entities/song_sort_option.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

typedef SearchLibraryResult = ({
  List<Song> songs,
  List<String> artists,
  List<String> albums,
});

/// Performs a global search across the library using FTS5.
/// Queries songs, distinct artists, and distinct albums concurrently.
final class SearchLibraryUseCase
    implements UseCase<SearchLibraryResult, String> {
  SearchLibraryUseCase(this._songRepository);

  final SongRepository _songRepository;

  @override
  Future<Result<SearchLibraryResult, Failure>> call(String query) async {
    if (query.trim().isEmpty) {
      return const Ok((
        songs: <Song>[],
        artists: <String>[],
        albums: <String>[],
      ));
    }

    // Run all three FTS5 queries concurrently
    final results = await Future.wait([
      _songRepository.searchSongs(
        query,
        sortOption: SongSortOption.title,
        isAscending: true,
      ),
      _songRepository.searchArtists(query),
      _songRepository.searchAlbums(query),
    ]);

    final songsResult = results[0] as Result<List<Song>, Failure>;
    final artistsResult = results[1] as Result<List<String>, Failure>;
    final albumsResult = results[2] as Result<List<String>, Failure>;

    if (songsResult.isErr) {
      return Err(songsResult.when(ok: (_) => throw Exception(), err: (e) => e));
    }
    if (artistsResult.isErr) {
      return Err(
          artistsResult.when(ok: (_) => throw Exception(), err: (e) => e));
    }
    if (albumsResult.isErr) {
      return Err(
          albumsResult.when(ok: (_) => throw Exception(), err: (e) => e));
    }

    return Ok((
      songs: songsResult.valueOrNull!,
      artists: artistsResult.valueOrNull!,
      albums: albumsResult.valueOrNull!,
    ));
  }
}
