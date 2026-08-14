import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/backup_repository.dart';
import '../local/app_database.dart';

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<Result<void, Failure>> createBackup(String destinationPath) async {
    try {
      // Force SQLite to write any pending WAL data to the main file
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

      final supportDir = await getApplicationSupportDirectory();
      final encoder = ZipFileEncoder();
      
      // Create the zip file at the user-selected destination
      encoder.create(destinationPath);

      // Add the database file
      final dbFile = File(p.join(supportDir.path, 'nexo.sqlite'));
      if (dbFile.existsSync()) {
        await encoder.addFile(dbFile);
      }

      // Add the cached cover arts
      final coversDir = Directory(p.join(supportDir.path, 'covers'));
      if (coversDir.existsSync()) {
        await encoder.addDirectory(coversDir);
      }

      await encoder.close();
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to create backup: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> restoreBackup(String zipPath) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final tempDir = Directory(p.join(supportDir.path, 'temp_restore'));
      
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      tempDir.createSync();

      // Extract the zip to a temporary folder
      await extractFileToDisk(zipPath, tempDir.path);

      final extractedDb = File(p.join(tempDir.path, 'nexo.sqlite'));
      if (!extractedDb.existsSync()) {
        return const Err(ValidationFailure('Invalid backup file: nexo.sqlite not found.'));
      }

      // Close the current database connection to allow overwriting
      await _db.close();

      // Overwrite the database file
      extractedDb.copySync(p.join(supportDir.path, 'nexo.sqlite'));

      // Overwrite the cover arts
      final extractedCovers = Directory(p.join(tempDir.path, 'covers'));
      final targetCovers = Directory(p.join(supportDir.path, 'covers'));
      
      if (extractedCovers.existsSync()) {
        if (targetCovers.existsSync()) targetCovers.deleteSync(recursive: true);
        // In Dart, renaming a directory acts as a fast "move" operation
        extractedCovers.renameSync(targetCovers.path);
      }

      tempDir.deleteSync(recursive: true);
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to restore backup: $e'));
    }
  }
}