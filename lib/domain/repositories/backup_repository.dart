import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

abstract interface class BackupRepository {
  Future<Result<void, Failure>> createBackup(String destinationPath);
  Future<Result<void, Failure>> restoreBackup(String zipPath);
}