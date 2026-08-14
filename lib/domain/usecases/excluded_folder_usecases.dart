import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/excluded_folder.dart';
import '../repositories/excluded_folder_repository.dart';
import 'use_case.dart';

final class GetExcludedFoldersUseCase
    implements UseCase<List<ExcludedFolder>, NoParams> {
  GetExcludedFoldersUseCase(this._repository);
  final ExcludedFolderRepository _repository;

  @override
  Future<Result<List<ExcludedFolder>, Failure>> call(NoParams params) {
    return _repository.getAll();
  }
}

final class AddExcludedFolderUseCase implements UseCase<void, String> {
  AddExcludedFolderUseCase(this._repository);
  final ExcludedFolderRepository _repository;

  @override
  Future<Result<void, Failure>> call(String path) {
    return _repository.add(path);
  }
}

final class RemoveExcludedFolderUseCase implements UseCase<void, int> {
  RemoveExcludedFolderUseCase(this._repository);
  final ExcludedFolderRepository _repository;

  @override
  Future<Result<void, Failure>> call(int id) {
    return _repository.remove(id);
  }
}