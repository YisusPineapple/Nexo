import 'package:nexo/core/error/failures.dart';
import 'package:nexo/core/utils/result.dart';
import 'package:nexo/domain/entities/excluded_folder.dart';
import 'package:nexo/domain/repositories/excluded_folder_repository.dart';

/// In-memory stand-in for [ExcludedFolderRepository]. Mirrors the same
/// "lives beside the contract it exercises" policy used by
/// [FakeSongRepository] and [FakePlaybackRepository].
class FakeExcludedFolderRepository implements ExcludedFolderRepository {
  FakeExcludedFolderRepository({List<ExcludedFolder> initial = const []})
      : _folders = List.of(initial);

  final List<ExcludedFolder> _folders;
  int _nextId = 1;

  /// Test hook: when true, every call fails.
  bool failAll = false;

  @override
  Future<Result<List<ExcludedFolder>, Failure>> getAll() async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake excluded folder failure.'));
    }
    return Ok(List.unmodifiable(_folders));
  }

  @override
  Future<Result<void, Failure>> add(String path) async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake excluded folder failure.'));
    }
    final result = ExcludedFolder.create(id: _nextId++, path: path);
    return result.when(
      ok: (folder) {
        _folders.add(folder);
        return const Ok(null);
      },
      err: (e) => Err(e),
    );
  }

  @override
  Future<Result<void, Failure>> remove(int id) async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake excluded folder failure.'));
    }
    _folders.removeWhere((f) => f.id == id);
    return const Ok(null);
  }
}