import 'package:drift/drift.dart';

import 'playlists_table.dart';
import 'songs_table.dart';

@DataClassName('PlaylistSongRow')
class PlaylistSongs extends Table {
  TextColumn get playlistId => text().references(Playlists, #id)();
  IntColumn get position => integer()();

  /// References the stable integer id of [Songs]. See the column comment
  /// in `songs_table.dart` on why this id is a plain INTEGER PRIMARY KEY
  /// and never recycled.
  IntColumn get songId => integer().references(Songs, #id)();

  @override
  Set<Column> get primaryKey => {playlistId, position};
}
