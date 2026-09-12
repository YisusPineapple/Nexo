import 'package:drift/drift.dart';

import 'songs_table.dart';

/// Records every time a song is played. Used to build the "For You"
/// recommendations, "Recently Played", and listening statistics.
@DataClassName('PlaybackHistoryRow')
class PlaybackHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// References the stable integer id of [Songs]. See the column comment
  /// in `songs_table.dart` on why this id is a plain INTEGER PRIMARY KEY
  /// and never recycled.
  IntColumn get songId => integer().references(Songs, #id)();

  /// When the song was played (Epoch milliseconds, UTC).
  IntColumn get timestampUtcMs => integer()();
}
