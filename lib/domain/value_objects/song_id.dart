// lib/domain/value_objects/song_id.dart
//
// Zero-cost, compile-time-only wrapper around a Song's unique
// identifier. Implemented as a Dart 3 extension type rather than a
// wrapped class: at runtime a SongId IS the underlying String value
// (no boxing, no extra heap allocation per song), which matters when
// up to 15,000 Song entities are held in memory for library
// scrolling. The type system still prevents accidentally passing a
// SongId where an ArtistId or AlbumId is expected — a mistake plain
// String ids would allow silently.
extension type const SongId(String value) {}
