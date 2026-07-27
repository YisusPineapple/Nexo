// Identifies where the songs in a PlaybackQueue originated from. This
// is informational only — it drives UI labels ("Queue from Album: X")
// and will drive a future "refresh from source" action — but it never
// changes playback behavior, so it stays as a small sealed hierarchy
// instead of being folded into PlaybackQueue itself.
import '../value_objects/album_id.dart';
import '../value_objects/artist_id.dart';

sealed class QueueSource {
  const QueueSource();
}

final class ManualQueueSource extends QueueSource {
  const ManualQueueSource();

  @override
  bool operator ==(Object other) => other is ManualQueueSource;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class ArtistQueueSource extends QueueSource {
  const ArtistQueueSource({required this.artistId, required this.artistName});

  final ArtistId artistId;
  final String artistName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistQueueSource &&
          other.artistId == artistId &&
          other.artistName == artistName);

  @override
  int get hashCode => Object.hash(artistId, artistName);
}

final class AlbumQueueSource extends QueueSource {
  const AlbumQueueSource({required this.albumId, required this.albumName});

  final AlbumId albumId;
  final String albumName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumQueueSource &&
          other.albumId == albumId &&
          other.albumName == albumName);

  @override
  int get hashCode => Object.hash(albumId, albumName);
}

final class PlaylistQueueSource extends QueueSource {
  const PlaylistQueueSource({
    required this.playlistId,
    required this.playlistName,
  });

  // Stays String for now: PlaylistId is deferred until the Playlist
  // entity itself is designed (Fase de Playlists), so this type isn't
  // guessed at ahead of time.
  final String playlistId;
  final String playlistName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistQueueSource &&
          other.playlistId == playlistId &&
          other.playlistName == playlistName);

  @override
  int get hashCode => Object.hash(playlistId, playlistName);
}

final class GenreQueueSource extends QueueSource {
  const GenreQueueSource({required this.genreName});

  final String genreName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenreQueueSource && other.genreName == genreName);

  @override
  int get hashCode => genreName.hashCode;
}

/// Queue built from browsing a filesystem folder — the primary
/// browsing mode on Linux/Windows for a local FOSS player, per the
/// mandatory "Carpetas" library view.
final class FolderQueueSource extends QueueSource {
  const FolderQueueSource({
    required this.folderPath,
    required this.folderName,
  });

  final String folderPath;
  final String folderName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderQueueSource &&
          other.folderPath == folderPath &&
          other.folderName == folderName);

  @override
  int get hashCode => Object.hash(folderPath, folderName);
}
