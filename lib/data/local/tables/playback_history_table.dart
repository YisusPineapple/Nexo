import 'package:drift/drift.dart';

import 'songs_table.dart';

/// Records every time a song is played. Used to build the "For You"
/// recommendations, "Recently Played", and listening statistics.
@DataClassName('PlaybackHistoryRow')
class PlaybackHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get songId => text().references(Songs, #id)();
  
  /// When the song was played (Epoch milliseconds, UTC).
  IntColumn get timestampUtcMs => integer()();
}