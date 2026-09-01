import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/app_version_info.dart';
import '../repositories/app_version_repository.dart';
import 'use_case.dart';

/// Wraps [AppVersionRepository.getVersionInfo] — kept as its own use
/// case only for consistency with every other repository method in
/// this app (see GetAllSongsUseCase's own docs on this same policy),
/// not because there is any business rule here today.
final class GetAppVersionUseCase implements UseCase<AppVersionInfo, NoParams> {
  GetAppVersionUseCase(this._repository);

  final AppVersionRepository _repository;

  @override
  Future<Result<AppVersionInfo, Failure>> call(NoParams params) {
    return _repository.getVersionInfo();
  }
}
