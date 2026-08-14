import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/library_folder.dart';
import '../../domain/repositories/library_folder_repository.dart';
import '../local/app_database.dart';

class LibraryFolderRepositoryImpl implements LibraryFolderRepository {
  LibraryFolderRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<Result<List<LibraryFolder>, Failure>> getIndexedFolders() async {
    try {
      final rows = await _db.select(_db.indexedFolders).get();
      final folders = <LibraryFolder>[];
      for (final row in rows) {
        final result = LibraryFolder.create(
          path: row.path,
          dateAddedUtc: DateTime.fromMillisecondsSinceEpoch(row.dateAddedUtcMs, isUtc: true),
        );
        if (result.isOk) folders.add(result.valueOrNull!);
      }
      return Ok(folders);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch indexed folders.', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> addIndexedFolder(String path) async {
    try {
      await _db.into(_db.indexedFolders).insertOnConflictUpdate(
            IndexedFoldersCompanion.insert(
              path: path,
              dateAddedUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
            ),
          );
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to add indexed folder.', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> removeIndexedFolder(String path) async {
    try {
      await (_db.delete(_db.indexedFolders)..where((t) => t.path.equals(path))).go();
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to remove indexed folder.', cause: e));
    }
  }

  @override
  Future<Result<List<ExcludedFolder>, Failure>> getExcludedFolders() async {
    try {
      final rows = await _db.select(_db.excludedFolders).get();
      final folders = <ExcludedFolder>[];
      for (final row in rows) {
        final result = ExcludedFolder.create(
          path: row.path,
          dateAddedUtc: DateTime.fromMillisecondsSinceEpoch(row.dateAddedUtcMs, isUtc: true),
        );
        if (result.isOk) folders.add(result.valueOrNull!);
      }
      return Ok(folders);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch excluded folders.', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> addExcludedFolder(String path) async {
    try {
      await _db.into(_db.excludedFolders).insertOnConflictUpdate(
            ExcludedFoldersCompanion.insert(
              path: path,
              dateAddedUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
            ),
          );
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to add excluded folder.', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> removeExcludedFolder(String path) async {
    try {
      await (_db.delete(_db.excludedFolders)..where((t) => t.path.equals(path))).go();
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to remove excluded folder.', cause: e));
    }
  }
}