import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/excluded_folder.dart';

abstract interface class ExcludedFolderRepository {
  Future<Result<List<ExcludedFolder>, Failure>> getAll();
  Future<Result<void, Failure>> add(String path);
  Future<Result<void, Failure>> remove(int id);
}