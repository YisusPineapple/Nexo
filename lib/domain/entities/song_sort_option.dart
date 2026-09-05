/// Defines the available sorting criteria for songs.
/// Kept in the Domain layer so repositories and use cases can depend
/// on it without importing UI/Presentation code.
enum SongSortOption {
  title,
  artist,
  album,
  year,
  duration,
  dateAdded,
}