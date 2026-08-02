import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/song.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

/// Wraps [SongRepository.searchSongs]. The 300ms debounce BIBLIOTECA's
/// search bar needs is a Presentation timing concern (see that
/// method's own docs) and stays out of this use case entirely — it
/// runs un-throttled on every call, exactly like the repository it
/// wraps.
final class SearchSongsUseCase implements UseCase<List<Song>, String> {
  SearchSongsUseCase(this._songRepository);

  final SongRepository _songRepository;

  @override
  Future<Result<List<Song>, Failure>> call(String query) {
    return _songRepository.searchSongs(query);
  }
}