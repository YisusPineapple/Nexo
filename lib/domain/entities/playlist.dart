import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../value_objects/playlist_id.dart';

final class Playlist {
  const Playlist._({
    required this.id,
    required this.name,
    required this.dateCreated,
  });

  final PlaylistId id;
  final String name;
  final DateTime dateCreated;

  static Result<Playlist, Failure> create({
    required PlaylistId id,
    required String name,
    required DateTime dateCreated,
  }) {
    if (name.trim().isEmpty) {
      return const Err(ValidationFailure('Playlist name cannot be empty.'));
    }
    return Ok(Playlist._(
      id: id,
      name: name.trim(),
      dateCreated: dateCreated,
    ));
  }

  Playlist copyWith({String? name}) {
    return Playlist._(
      id: id,
      name: name ?? this.name,
      dateCreated: dateCreated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Playlist && other.id == id);

  @override
  int get hashCode => id.hashCode;
}