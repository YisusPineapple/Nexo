import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/song.dart';
import '../entities/song_sort_option.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

typedef GetAllSongsParams = ({
  SongSortOption sortOption,
  bool isAscending,
});

/// Wraps [SongRepository.getAllSongs] — kept as its own use case,
/// like [RefreshLibraryUseCase], as the seam where future
/// library-wide rules would go (e.g. hiding [Song.isMissing] entries
/// by default, or a future parental/privacy filter) without
/// Presentation ever depending on [SongRepository] directly.
final class GetAllSongsUseCase
    implements UseCase<List<Song>, GetAllSongsParams> {
  GetAllSongsUseCase(this._songRepository);

  final SongRepository _songRepository;

  @override
  Future<Result<List<Song>, Failure>> call(GetAllSongsParams params) {
    return _songRepository.getAllSongs(
      sortOption: params.sortOption,
      isAscending: params.isAscending,
    );
  }
}
