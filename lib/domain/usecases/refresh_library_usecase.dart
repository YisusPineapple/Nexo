import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

final class RefreshLibraryUseCase implements UseCase<void, NoParams> {
  RefreshLibraryUseCase(this._songRepository);

  final SongRepository _songRepository;

  @override
  Future<Result<void, Failure>> call(
    NoParams params, {
    void Function(int current, int total)? onProgress, // FIX: Added onProgress
  }) {
    return _songRepository.refresh(onProgress: onProgress);
  }
}