import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

/// Wraps [SongRepository.indexDirectories] with validation that
/// belongs in Domain, not in the Data-layer scanner: whether the list
/// of paths is well-formed is a pure question about the INPUT itself,
/// answerable without touching the filesystem.
///
/// Deliberately does NOT attempt path normalization (trailing
/// slashes, symlinks, case-insensitive filesystems on Windows) — that
/// requires actual filesystem knowledge the Data-layer scanner has
/// and Domain doesn't, so a path that's merely a different STRING but
/// resolves to the same directory won't be caught here. This only
/// rejects paths that are identical as written.
final class IndexDirectoriesUseCase implements UseCase<void, List<String>> {
  IndexDirectoriesUseCase(this._songRepository);

  final SongRepository _songRepository;

  @override
  Future<Result<void, Failure>> call(List<String> directoryPaths) async {
    if (directoryPaths.isEmpty) {
      return const Err(
        ValidationFailure('Cannot index an empty list of directories.'),
      );
    }
    if (directoryPaths.any((path) => path.isEmpty)) {
      return const Err(
        ValidationFailure('directoryPaths cannot contain an empty path.'),
      );
    }
    if (directoryPaths.toSet().length != directoryPaths.length) {
      return const Err(ValidationFailure(
        'directoryPaths contains duplicate entries; each directory '
        'should be indexed once.',
      ));
    }
    return _songRepository.indexDirectories(directoryPaths);
  }
}
