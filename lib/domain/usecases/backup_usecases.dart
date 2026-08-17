import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../repositories/backup_repository.dart';
import 'use_case.dart';

typedef BackupParams = ({
  bool includeLibrary,
  bool includePlaylists,
  bool includeSettings,
  String? destinationDirectory,
});

final class CreateBackupUseCase implements UseCase<String, BackupParams> {
  CreateBackupUseCase(this._repository);
  final BackupRepository _repository;

  @override
  Future<Result<String, Failure>> call(BackupParams params) {
    return _repository.createBackup(
      includeLibrary: params.includeLibrary,
      includePlaylists: params.includePlaylists,
      includeSettings: params.includeSettings,
      destinationDirectory: params.destinationDirectory,
    );
  }
}

final class RestoreBackupUseCase implements UseCase<void, String> {
  RestoreBackupUseCase(this._repository);
  final BackupRepository _repository;

  @override
  Future<Result<void, Failure>> call(String zipPath) {
    return _repository.restoreBackup(zipPath);
  }
}
