import 'package:nexo/core/error/failures.dart';
import 'package:nexo/core/utils/result.dart';
import 'package:nexo/domain/entities/library_folder.dart';
import 'package:nexo/domain/repositories/library_folder_repository.dart';

/// In-memory stand-in for [LibraryFolderRepository]. Mirrors the same
/// "lives beside the contract it exercises" policy used by
/// [FakeSongRepository] and [FakePlaybackRepository].
class FakeLibraryFolderRepository implements LibraryFolderRepository {
  FakeLibraryFolderRepository({
    List<LibraryFolder> initialIndexed = const [],
    List<ExcludedFolder> initialExcluded = const [],
  })  : _indexed = List.of(initialIndexed),
        _excluded = List.of(initialExcluded);

  final List<LibraryFolder> _indexed;
  final List<ExcludedFolder> _excluded;

  /// Test hook: when true, every call fails.
  bool failAll = false;

  @override
  Future<Result<List<LibraryFolder>, Failure>> getIndexedFolders() async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake folder failure.'));
    }
    return Ok(List.unmodifiable(_indexed));
  }

  @override
  Future<Result<void, Failure>> addIndexedFolder(String path) async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake folder failure.'));
    }
    final result = LibraryFolder.create(
      path: path,
      dateAddedUtc: DateTime.now().toUtc(),
    );
    return result.when(
      ok: (folder) {
        _indexed.add(folder);
        return const Ok(null);
      },
      err: (e) => Err(e),
    );
  }

  @override
  Future<Result<void, Failure>> removeIndexedFolder(String path) async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake folder failure.'));
    }
    _indexed.removeWhere((f) => f.path == path);
    return const Ok(null);
  }

  @override
  Future<Result<List<ExcludedFolder>, Failure>> getExcludedFolders() async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake folder failure.'));
    }
    return Ok(List.unmodifiable(_excluded));
  }

  @override
  Future<Result<void, Failure>> addExcludedFolder(String path) async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake folder failure.'));
    }
    final result = ExcludedFolder.create(
      path: path,
      dateAddedUtc: DateTime.now().toUtc(),
    );
    return result.when(
      ok: (folder) {
        _excluded.add(folder);
        return const Ok(null);
      },
      err: (e) => Err(e),
    );
  }

  @override
  Future<Result<void, Failure>> removeExcludedFolder(String path) async {
    if (failAll) {
      return const Err(UnexpectedFailure('Fake folder failure.'));
    }
    _excluded.removeWhere((f) => f.path == path);
    return const Ok(null);
  }
}