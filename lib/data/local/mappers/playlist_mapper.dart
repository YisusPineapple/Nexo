import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/value_objects/playlist_id.dart';
import '../app_database.dart';

class PlaylistMapper {
  const PlaylistMapper();

  Result<Playlist, Failure> toEntity(PlaylistRow row) {
    return Playlist.create(
      id: PlaylistId(row.id),
      name: row.name,
      dateCreated: DateTime.fromMillisecondsSinceEpoch(
        row.dateCreatedUtcMs,
        isUtc: true,
      ),
    );
  }

  PlaylistsCompanion toCompanion(Playlist playlist) {
    return PlaylistsCompanion.insert(
      id: playlist.id.value,
      name: playlist.name,
      dateCreatedUtcMs: playlist.dateCreated.toUtc().millisecondsSinceEpoch,
    );
  }
}
