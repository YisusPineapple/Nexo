import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

/// Wraps [SongRepository.refresh] — the manual re-scan trigger
/// standing in for live watch mode until the real file-watcher
/// integration is designed (see [SongRepository]'s class docs).
/// Trivial today by design: once the watcher lands, this use case is
/// where the "should we even trigger a manual refresh, or is the
/// watcher already covering this" decision would go, without
/// disturbing the contract callers already depend on.
final class RefreshLibraryUseCase implements UseCase<void, NoParams> {
  RefreshLibraryUseCase(this._songRepository);

  final SongRepository _songRepository;

  @override
  Future<Result<void, Failure>> call(NoParams params) {
    return _songRepository.refresh();
  }
}
