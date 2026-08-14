import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/library_folder.dart';
import '../../domain/usecases/index_directories_usecase.dart';
import 'library_providers.dart';
import 'repository_providers.dart';

final indexedFoldersProvider = FutureProvider<List<LibraryFolder>>((ref) async {
  final repo = ref.watch(libraryFolderRepositoryProvider);
  final result = await repo.getIndexedFolders();
  return result.when(ok: (folders) => folders, err: (e) => throw e);
});

final excludedFoldersProvider = FutureProvider<List<ExcludedFolder>>((ref) async {
  final repo = ref.watch(libraryFolderRepositoryProvider);
  final result = await repo.getExcludedFolders();
  return result.when(ok: (folders) => folders, err: (e) => throw e);
});

final folderManagementControllerProvider = Provider<FolderManagementController>((ref) {
  return FolderManagementController(ref);
});

class FolderManagementController {
  FolderManagementController(this._ref);
  final Ref _ref;

  Future<String?> addIndexedFolder(String path) async {
    final repo = _ref.read(libraryFolderRepositoryProvider);
    final addResult = await repo.addIndexedFolder(path);
    if (addResult.isErr) {
      return addResult.when(ok: (_) => null, err: (e) => e.message);
    }

    final indexUseCase = IndexDirectoriesUseCase(_ref.read(songRepositoryProvider));
    final indexResult = await indexUseCase.call([path]);
    _ref.invalidate(indexedFoldersProvider);
    _ref.invalidate(sortedSongsProvider);
    return indexResult.when(ok: (_) => null, err: (e) => e.message);
  }

  Future<String?> removeIndexedFolder(String path) async {
    final repo = _ref.read(libraryFolderRepositoryProvider);
    final result = await repo.removeIndexedFolder(path);
    if (result.isOk) _ref.invalidate(indexedFoldersProvider);
    return result.when(ok: (_) => null, err: (e) => e.message);
  }

  Future<String?> addExcludedFolder(String path) async {
    final repo = _ref.read(libraryFolderRepositoryProvider);
    final result = await repo.addExcludedFolder(path);
    if (result.isOk) _ref.invalidate(excludedFoldersProvider);
    return result.when(ok: (_) => null, err: (e) => e.message);
  }

  Future<String?> removeExcludedFolder(String path) async {
    final repo = _ref.read(libraryFolderRepositoryProvider);
    final result = await repo.removeExcludedFolder(path);
    if (result.isOk) _ref.invalidate(excludedFoldersProvider);
    return result.when(ok: (_) => null, err: (e) => e.message);
  }
}