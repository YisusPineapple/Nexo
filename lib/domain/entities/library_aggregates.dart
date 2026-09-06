/// Domain entities representing grouped collections of songs.
/// These replace the ad-hoc Tuples/Records previously used in the UI layer,
/// enforcing a strict contract between the Data and Presentation layers.
library;

enum AlbumSortOption { name, artist, songCount }

enum ArtistSortOption { name, songCount, albumCount }

final class Album {
  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.songCount,
    this.coverArtPath,
  });

  final String id;
  final String name;
  final String artist;
  final int songCount;
  final String? coverArtPath;
}

final class Artist {
  const Artist({
    required this.name,
    required this.songCount,
    required this.albumCount,
    required this.collaborationCount,
    this.coverArtPath,
  });

  final String name;
  final int songCount;
  final int albumCount;
  final int collaborationCount;
  final String? coverArtPath;
}

final class Genre {
  const Genre({
    required this.name,
    required this.songCount,
  });

  final String name;
  final int songCount;
}

final class FolderSummary {
  const FolderSummary({
    required this.path,
    required this.name,
    required this.songCount,
  });

  final String path;
  final String name;
  final int songCount;
}
