import 'package:drift/drift.dart';

import 'playlists_table.dart';
import 'songs_table.dart';

@DataClassName('PlaylistSongRow')
class PlaylistSongs extends Table {
  TextColumn get playlistId => text().references(Playlists, #id)();
  IntColumn get position => integer()();
  TextColumn get songId => text().references(Songs, #id)();

  @override
  Set<Column> get primaryKey => {playlistId, position};
}