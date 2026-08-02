import '../../domain/entities/song.dart';

/// How LIBRARY's Songs view orders its list. The six options named
/// in PART A (title, artist, album, year, duration, dateAdded).
enum SongSortOption {
  title('Title'),
  artist('Artist'),
  album('Album'),
  year('Year'),
  duration('Duration'),
  dateAdded('Date added');

  const SongSortOption(this.label);

  final String label;
}

/// Ascending comparator for [option]. Nullable fields ([Song.year],
/// [Song.albumId]) sort last when absent, rather than crashing a
/// whole-list sort over one untagged file.
int compareSongs(Song a, Song b, SongSortOption option) {
  switch (option) {
    case SongSortOption.title:
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case SongSortOption.artist:
      return a.trackArtistId.value
          .toLowerCase()
          .compareTo(b.trackArtistId.value.toLowerCase());
    case SongSortOption.album:
      final albumA = a.albumId?.value.toLowerCase() ?? '';
      final albumB = b.albumId?.value.toLowerCase() ?? '';
      if (albumA.isEmpty && albumB.isEmpty) return 0;
      if (albumA.isEmpty) return 1;
      if (albumB.isEmpty) return -1;
      return albumA.compareTo(albumB);
    case SongSortOption.year:
      if (a.year == null && b.year == null) return 0;
      if (a.year == null) return 1;
      if (b.year == null) return -1;
      return a.year!.compareTo(b.year!);
    case SongSortOption.duration:
      return a.duration.compareTo(b.duration);
    case SongSortOption.dateAdded:
      return a.dateAddedUtc.compareTo(b.dateAddedUtc);
  }
}