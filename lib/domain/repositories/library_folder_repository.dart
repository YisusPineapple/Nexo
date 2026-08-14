import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/library_folder.dart';

/// Persistence contract for the user's library folder configuration.
/// Replaces the old in-memory Set of Strings in SongRepositoryImpl.
abstract interface class LibraryFolderRepository {
  Future<Result<List<LibraryFolder>, Failure>> getIndexedFolders();
  Future<Result<void, Failure>> addIndexedFolder(String path);
  Future<Result<void, Failure>> removeIndexedFolder(String path);

  Future<Result<List<ExcludedFolder>, Failure>> getExcludedFolders();
  Future<Result<void, Failure>> addExcludedFolder(String path);
  Future<Result<void, Failure>> removeExcludedFolder(String path);
}