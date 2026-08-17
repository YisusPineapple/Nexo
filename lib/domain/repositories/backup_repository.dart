import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

abstract interface class BackupRepository {
  Future<Result<String, Failure>> createBackup({
    required bool includeLibrary,
    required bool includePlaylists,
    required bool includeSettings,
  });

  Future<Result<void, Failure>> restoreBackup(String zipPath);
}
