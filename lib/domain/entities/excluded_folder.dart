import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

/// Represents a directory path that the indexer must completely ignore.
/// Used to prevent scanning podcasts, audiobooks, or system folders
/// that might be nested inside the user's main music library.
final class ExcludedFolder {
  const ExcludedFolder._({
    required this.id,
    required this.path,
  });

  final int id;
  final String path;

  static Result<ExcludedFolder, Failure> create({
    required int id,
    required String path,
  }) {
    if (path.trim().isEmpty) {
      return const Err(ValidationFailure('Excluded folder path cannot be empty.'));
    }
    return Ok(ExcludedFolder._(id: id, path: path.trim()));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ExcludedFolder && other.id == id);

  @override
  int get hashCode => id.hashCode;
}