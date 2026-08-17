import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/backup_repository.dart';
import '../local/app_database.dart';

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._db, this._baseDir);
  
  final AppDatabase _db;
  final String _baseDir;

  @override
  Future<Result<String, Failure>> createBackup({
    required bool includeLibrary,
    required bool includePlaylists,
    required bool includeSettings,
    String? destinationDirectory,
  }) async {
    try {
      // Sync WAL data to main DB without blocking active readers
      await _db.customStatement('PRAGMA wal_checkpoint(PASSIVE);');

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
          
      final backupDir = destinationDirectory != null
          ? Directory(destinationDirectory)
          : Directory(_baseDir);
          
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final zipPath = p.join(backupDir.path, 'nexo_backup_$timestamp.zip');
      final dbPath = p.join(_baseDir, 'nexo.sqlite');
      final coversPath = p.join(_baseDir, 'covers');

      // Isolate.run returns String? (null if success, error message if failed)
      final errorMessage = await Isolate.run(() {
        try {
          final encoder = ZipFileEncoder();
          encoder.create(zipPath);

          if (includeLibrary) {
            final dbFile = File(dbPath);
            if (dbFile.existsSync()) {
              // Copy DB to a temp file first to avoid SQLite lock issues during zip
              final tempDbPath = p.join(backupDir.path, 'temp_nexo_$timestamp.sqlite');
              dbFile.copySync(tempDbPath);
              encoder.addFile(File(tempDbPath), 'nexo.sqlite');
              File(tempDbPath).deleteSync(); // Clean up temp file
            }

            final coversDir = Directory(coversPath);
            if (coversDir.existsSync()) {
              // The archive package can crash if the directory is completely empty
              final hasFiles = coversDir.listSync().isNotEmpty;
              if (hasFiles) {
                encoder.addDirectory(coversDir);
              }
            }
          }

          if (includePlaylists || includeSettings) {
            // Additional payloads can be added here later
          }

          encoder.close();
          return null; // Success
        } catch (e) {
          return e.toString(); // Return the exact error message
        }
      });

      if (errorMessage != null) {
        return Err(UnexpectedFailure('Backup failed: $errorMessage'));
      }

      return Ok(zipPath);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to initialize backup: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> restoreBackup(String zipPath) async {
    try {
      final tempDir = Directory(p.join(_baseDir, 'temp_restore'));

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      // Extract in isolate to prevent UI freeze during restore
      final errorMessage = await Isolate.run(() {
        try {
          extractFileToDisk(zipPath, tempDir.path);
          return null;
        } catch (e) {
          return e.toString();
        }
      });

      if (errorMessage != null) {
        return Err(ValidationFailure('Failed to extract backup: $errorMessage'));
      }

      final extractedDb = File(p.join(tempDir.path, 'nexo.sqlite'));
      if (!await extractedDb.exists()) {
        return const Err(
          ValidationFailure('Invalid backup file: nexo.sqlite not found.'),
        );
      }

      await _db.close();
      await extractedDb.copy(p.join(_baseDir, 'nexo.sqlite'));

      final extractedCovers = Directory(p.join(tempDir.path, 'covers'));
      final targetCovers = Directory(p.join(_baseDir, 'covers'));
      
      if (await extractedCovers.exists()) {
        if (await targetCovers.exists()) {
          await targetCovers.delete(recursive: true);
        }
        await extractedCovers.rename(targetCovers.path);
      }

      await tempDir.delete(recursive: true);
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to restore backup: $e'));
    }
  }
}