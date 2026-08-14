import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

/// Represents a directory the user has explicitly added to their music library.
final class LibraryFolder {
  const LibraryFolder._({
    required this.path,
    required this.dateAddedUtc,
  });

  final String path;
  final DateTime dateAddedUtc;

  static Result<LibraryFolder, Failure> create({
    required String path,
    required DateTime dateAddedUtc,
  }) {
    if (path.trim().isEmpty) {
      return const Err(ValidationFailure('Library folder path cannot be empty.'));
    }
    return Ok(LibraryFolder._(path: path.trim(), dateAddedUtc: dateAddedUtc));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LibraryFolder && other.path == path);

  @override
  int get hashCode => path.hashCode;
}

/// Represents a directory the user has explicitly excluded from scanning.
final class ExcludedFolder {
  const ExcludedFolder._({
    required this.path,
    required this.dateAddedUtc,
  });

  final String path;
  final DateTime dateAddedUtc;

  static Result<ExcludedFolder, Failure> create({
    required String path,
    required DateTime dateAddedUtc,
  }) {
    if (path.trim().isEmpty) {
      return const Err(ValidationFailure('Excluded folder path cannot be empty.'));
    }
    return Ok(ExcludedFolder._(path: path.trim(), dateAddedUtc: dateAddedUtc));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ExcludedFolder && other.path == path);

  @override
  int get hashCode => path.hashCode;
}