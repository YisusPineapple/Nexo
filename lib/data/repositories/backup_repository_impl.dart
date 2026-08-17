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
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

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

      final result = await _compressInIsolate(
        dbPath: p.join(_baseDir, 'nexo.sqlite'),
        coversPath: p.join(_baseDir, 'covers'),
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

  static Future<void> _compressIsolateEntry(dynamic message) async {
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
          await encoder.addFile(dbFile, 'nexo.sqlite');
        }

        final coversDir = Directory(coversPath);
        if (coversDir.existsSync()) {
          await encoder.addDirectory(coversDir);
        }
      }

      if (includePlaylists || includeSettings) {
        // Additional payloads can be added here when their storage paths are defined.
      }

      await encoder.close();
      sendPort.send(true);
    } catch (e) {
      sendPort.send(false);
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

      await extractFileToDisk(zipPath, tempDir.path);

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
