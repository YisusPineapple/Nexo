import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/backup_usecases.dart';
import 'repository_providers.dart';

final backupControllerProvider = Provider<BackupController>((ref) {
  return BackupController(ref);
});

class BackupController {
  BackupController(this._ref);
  final Ref _ref;

  Future<String?> createBackup(String destinationPath) async {
    final useCase = CreateBackupUseCase(_ref.read(backupRepositoryProvider));
    final result = await useCase.call(destinationPath);
    return result.when(ok: (_) => null, err: (e) => e.message);
  }

  Future<String?> restoreBackup(String zipPath) async {
    final useCase = RestoreBackupUseCase(_ref.read(backupRepositoryProvider));
    final result = await useCase.call(zipPath);
    return result.when(ok: (_) => null, err: (e) => e.message);
  }
}