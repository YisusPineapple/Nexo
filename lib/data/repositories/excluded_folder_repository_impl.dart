import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/excluded_folder.dart';
import '../../domain/repositories/excluded_folder_repository.dart';
import '../local/app_database.dart';

class ExcludedFolderRepositoryImpl implements ExcludedFolderRepository {
  ExcludedFolderRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<Result<List<ExcludedFolder>, Failure>> getAll() async {
    try {
      final rows = await _db.select(_db.excludedFolders).get();
      final folders = <ExcludedFolder>[];
      for (final row in rows) {
        final result = ExcludedFolder.create(id: row.id, path: row.path);
        if (result.isOk) folders.add(result.valueOrNull!);
      }
      return Ok(folders);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch excluded folders', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> add(String path) async {
    try {
      await _db.into(_db.excludedFolders).insertOnConflictUpdate(
            ExcludedFoldersCompanion.insert(path: path),
          );
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to add excluded folder', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> remove(int id) async {
    try {
      await (_db.delete(_db.excludedFolders)..where((t) => t.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to remove excluded folder', cause: e));
    }
  }
}