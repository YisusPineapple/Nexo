import 'package:drift/drift.dart';

import '../converters/queue_source_converter.dart';
import '../converters/repeat_mode_converter.dart';

@DataClassName('PlaybackQueueRow')
class PlaybackQueues extends Table {
  TextColumn get id => text()();

  IntColumn get currentIndex => integer()();

  TextColumn get repeatMode => text().map(const RepeatModeConverter())();
  TextColumn get source => text().map(const QueueSourceConverter())();
  BoolColumn get shuffleEnabled =>
      boolean().withDefault(const Constant(false))();

  IntColumn get preShuffleCurrentIndex => integer().nullable()();

  IntColumn get positionMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
