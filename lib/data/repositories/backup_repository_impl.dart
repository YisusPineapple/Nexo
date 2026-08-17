import 'dart:io';
import 'dart:isolate';

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
  Future<Result<String, Failure>> createBackup({
    required bool includeLibrary,
    required bool includePlaylists,
    required bool includeSettings,
  }) async {
    try {
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

      final supportDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final backupDir = Directory(p.join(supportDir.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final zipPath = p.join(backupDir.path, 'nexo_backup_$timestamp.zip');

      final result = await _compressInIsolate(
        dbPath: p.join(supportDir.path, 'nexo.sqlite'),
        coversPath: p.join(supportDir.path, 'covers'),
        zipPath: zipPath,
        includeLibrary: includeLibrary,
        includePlaylists: includePlaylists,
        includeSettings: includeSettings,
      );

      if (!result) {
        return const Err(UnexpectedFailure('Failed to compress backup files.'));
      }

      return Ok(zipPath);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to create backup: $e'));
    }
  }

  Future<bool> _compressInIsolate({
    required String dbPath,
    required String coversPath,
    required String zipPath,
    required bool includeLibrary,
    required bool includePlaylists,
    required bool includeSettings,
  }) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _compressIsolateEntry,
      (
        receivePort.sendPort,
        dbPath,
        coversPath,
        zipPath,
        includeLibrary,
        includePlaylists,
        includeSettings,
      ),
    );
    final result = await receivePort.first as bool;
    receivePort.close();
    return result;
  }

  static void _compressIsolateEntry(dynamic message) {
    final (
      sendPort,
      dbPath,
      coversPath,
      zipPath,
      includeLibrary,
      includePlaylists,
      includeSettings,
    ) = message as (
      SendPort,
      String,
      String,
      String,
      bool,
      bool,
      bool,
    );

    try {
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      if (includeLibrary) {
        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          encoder.addFile(dbFile);
        }

        final coversDir = Directory(coversPath);
        if (coversDir.existsSync()) {
          encoder.addDirectory(coversDir);
        }
      }

      if (includePlaylists || includeSettings) {
        // Additional payloads can be added here when their storage paths are defined.
      }

      encoder.close();
      sendPort.send(true);
    } catch (e) {
      sendPort.send(false);
    }
  }

  @override
  Future<Result<void, Failure>> restoreBackup(String zipPath) async {
    try {
      final supportDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory(p.join(supportDir.path, 'temp_restore'));

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      await extractFileToDisk(zipPath, tempDir.path);

      final extractedDb = File(p.join(tempDir.path, 'nexo.sqlite'));
      if (!await extractedDb.exists()) {
        return const Err(
          ValidationFailure('Invalid backup file: nexo.sqlite not found.'),
        );
      }

      await _db.close();
      await extractedDb.copy(p.join(supportDir.path, 'nexo.sqlite'));

      final extractedCovers = Directory(p.join(tempDir.path, 'covers'));
      final targetCovers = Directory(p.join(supportDir.path, 'covers'));
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
