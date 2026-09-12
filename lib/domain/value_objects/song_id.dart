// lib/domain/value_objects/song_id.dart
//
// Zero-cost, compile-time-only wrapper around a Song's unique
// identifier. Implemented as a Dart 3 extension type rather than a
// wrapped class: at runtime a SongId IS the underlying int value (no
// boxing, no extra heap allocation per song), which matters when up to
// 15,000 Song entities are held in memory for library scrolling. The
// type system still prevents accidentally passing a SongId where an
// ArtistId or AlbumId is expected — a mistake plain int ids would
// allow silently.
//
// This is the SQLite-assigned INTEGER PRIMARY KEY (the rowid alias of
// the `songs` table), NOT the file path. It is stable across a file
// being renamed or moved within the same indexed folder — that
// stability is the entire point of the schema 15 migration that
// replaced the previous "id = file path" scheme. See
// `songs_table.dart` for the no-hard-delete invariant this relies on.
extension type const SongId(int value) {}
