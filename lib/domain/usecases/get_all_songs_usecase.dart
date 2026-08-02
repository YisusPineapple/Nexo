import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/song.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

/// Wraps [SongRepository.getAllSongs] — kept as its own use case,
/// like [RefreshLibraryUseCase], as the seam where future
/// library-wide rules would go (e.g. hiding [Song.isMissing] entries
/// by default, or a future parental/privacy filter) without
/// Presentation ever depending on [SongRepository] directly.
final class GetAllSongsUseCase implements UseCase<List<Song>, NoParams> {
  GetAllSongsUseCase(this._songRepository);

  final SongRepository _songRepository;

  @override
  Future<Result<List<Song>, Failure>> call(NoParams params) {
    return _songRepository.getAllSongs();
  }
}