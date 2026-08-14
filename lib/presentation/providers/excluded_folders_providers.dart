import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/excluded_folder.dart';
import '../../domain/usecases/excluded_folder_usecases.dart';
import 'repository_providers.dart';

final excludedFoldersProvider = FutureProvider<List<ExcludedFolder>>((ref) async {
  final repo = ref.watch(excludedFolderRepositoryProvider);
  final result = await repo.getAll();
  return result.when(ok: (folders) => folders, err: (e) => throw e);
});

final excludedFoldersControllerProvider =
    Provider<ExcludedFoldersController>((ref) {
  return ExcludedFoldersController(ref);
});

class ExcludedFoldersController {
  ExcludedFoldersController(this._ref);
  final Ref _ref;

  Future<void> add(String path) async {
    final useCase = AddExcludedFolderUseCase(
        _ref.read(excludedFolderRepositoryProvider));
    final result = await useCase.call(path);
    if (result.isOk) {
      _ref.invalidate(excludedFoldersProvider);
    }
  }

  Future<void> remove(int id) async {
    final useCase = RemoveExcludedFolderUseCase(
        _ref.read(excludedFolderRepositoryProvider));
    final result = await useCase.call(id);
    if (result.isOk) {
      _ref.invalidate(excludedFoldersProvider);
    }
  }
}