import 'package:drift/drift.dart';

import '../converters/queue_source_converter.dart';
import '../converters/repeat_mode_converter.dart';

/// Drift table backing the "static" fields of a [PlaybackQueue] — its
/// position and configuration. The actual song ORDER (both the live
/// order and, while shuffled, the pre-shuffle snapshot) is
/// deliberately NOT a column here: see [QueueSongs]'s class docs for
/// why that lives in its own ordered join table instead.
@DataClassName('PlaybackQueueRow')
class PlaybackQueues extends Table {
  TextColumn get id => text()();

  /// Mirrors [PlaybackQueue.currentIndex] exactly, including its -1
  /// double meaning (empty queue OR a queue that finished with
  /// RepeatMode.off) — read that field's Domain docstring before
  /// touching this column or any code that writes to it.
  IntColumn get currentIndex => integer()();

  TextColumn get repeatMode => text().map(const RepeatModeConverter())();
  TextColumn get source => text().map(const QueueSourceConverter())();
  BoolColumn get shuffleEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Non-null only while [shuffleEnabled] is true — mirrors
  /// [PlaybackQueue.preShuffleCurrentIndex] exactly.
  IntColumn get preShuffleCurrentIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
