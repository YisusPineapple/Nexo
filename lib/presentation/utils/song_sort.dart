import '../../domain/entities/song.dart';

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

int compareSongs(Song a, Song b, SongSortOption option, bool isAscending) {
  int result;
  switch (option) {
    case SongSortOption.title:
      result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      break;
    case SongSortOption.artist:
      result = a.trackArtistId.value
          .toLowerCase()
          .compareTo(b.trackArtistId.value.toLowerCase());
      break;
    case SongSortOption.album:
      final albumA = a.albumId?.value.toLowerCase() ?? '';
      final albumB = b.albumId?.value.toLowerCase() ?? '';
      if (albumA.isEmpty && albumB.isEmpty) {
        result = 0;
      } else if (albumA.isEmpty) {
        result = 1;
      } else if (albumB.isEmpty) {
        result = -1;
      } else {
        result = albumA.compareTo(albumB);
      }
      break;
    case SongSortOption.year:
      if (a.year == null && b.year == null) {
        result = 0;
      } else if (a.year == null) {
        result = 1;
      } else if (b.year == null) {
        result = -1;
      } else {
        result = a.year!.compareTo(b.year!);
      }
      break;
    case SongSortOption.duration:
      result = a.duration.compareTo(b.duration);
      break;
    case SongSortOption.dateAdded:
      result = a.dateAddedUtc.compareTo(b.dateAddedUtc);
      break;
  }
  return isAscending ? result : -result;
}
