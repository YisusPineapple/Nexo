import 'package:drift/drift.dart';

import 'playback_queues_table.dart';
import 'songs_table.dart';

/// Ordered join table between [PlaybackQueues] and [Songs].
///
/// [listKind] distinguishes the queue's LIVE order ('current') from
/// the pre-shuffle snapshot Domain keeps so `withShuffleDisabled` can
/// restore it exactly ([PlaybackQueue.preShuffleOrder]'s docstring) —
/// one physical table serves both lists instead of duplicating this
/// schema for each.
///
/// [position] is 0-based and, together with ([queueId], [listKind]),
/// is what makes a duplicated song in the same queue representable at
/// all: two rows can share the same [songId] at two different
/// [position]s. Nothing querying this table should ever look up a
/// song by [songId] alone within a queue — that is precisely the bug
/// Domain's positional reorder/shuffle/currentIndex tracking exists to
/// avoid (see playback_queue.dart's class docs on this exact point).
@DataClassName('QueueSongRow')
class QueueSongs extends Table {
  TextColumn get queueId => text().references(PlaybackQueues, #id)();

  /// 'current' or 'preShuffle'. Plain String, not a converted enum:
  /// this is Data-layer-only plumbing with no Domain-side equivalent
  /// type, so a converter would be ceremony around two literals.
  TextColumn get listKind => text()();

  IntColumn get position => integer()();
  TextColumn get songId => text().references(Songs, #id)();

  @override
  Set<Column> get primaryKey => {queueId, listKind, position};
}
