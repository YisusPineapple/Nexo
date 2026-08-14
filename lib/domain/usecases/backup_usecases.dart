import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../repositories/backup_repository.dart';
import 'use_case.dart';

final class CreateBackupUseCase implements UseCase<void, String> {
  CreateBackupUseCase(this._repository);
  final BackupRepository _repository;

  @override
  Future<Result<void, Failure>> call(String destinationPath) {
    return _repository.createBackup(destinationPath);
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