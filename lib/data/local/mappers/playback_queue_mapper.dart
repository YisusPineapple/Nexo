import 'package:drift/drift.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/playback_queue.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/value_objects/queue_id.dart';
import '../app_database.dart';

/// The only file allowed to know about BOTH [PlaybackQueue] (Domain)
/// and [PlaybackQueueRow]/[QueueSongRow] (Drift) — mirrors
/// [SongMapper]'s role for [Song].
///
/// Takes already-resolved [Song] lists rather than [SongId]s: this
/// mapper has zero DB/IO knowledge of its own. Resolving which songs
/// a queue's rows reference is PlaybackRepositoryImpl's job (it needs
/// a DB round-trip anyway), done BEFORE calling [toEntity].
class PlaybackQueueMapper {
  const PlaybackQueueMapper();

  /// Reconstructs a [PlaybackQueue] from its row plus the resolved
  /// [Song]s for its 'current' order and, if shuffled, its
  /// 'preShuffle' snapshot — both already in persisted order.
  ///
  /// See this file's own class docs for why a shuffled queue needs
  /// TWO steps to rebuild (create the pre-shuffle state, then replay
  /// withShuffleEnabled) rather than one direct constructor call.
  Result<PlaybackQueue, Failure> toEntity({
    required PlaybackQueueRow row,
    required List<Song> currentSongs,
    List<Song>? preShuffleSongs,
  }) {
    if (!row.shuffleEnabled) {
      return PlaybackQueue.create(
        id: QueueId(row.id),
        songs: currentSongs,
        currentIndex: row.currentIndex,
        repeatMode: row.repeatMode,
        source: row.source,
      );
    }

    final preShuffleResult = PlaybackQueue.create(
      id: QueueId(row.id),
      songs: preShuffleSongs ?? const [],
      currentIndex: row.preShuffleCurrentIndex ?? -1,
      repeatMode: row.repeatMode,
      source: row.source,
    );

    return switch (preShuffleResult) {
      Err(error: final e) => Err(e),
      Ok(value: final preShuffleQueue) => preShuffleQueue.withShuffleEnabled(
          shuffled: currentSongs,
          newCurrentIndex: row.currentIndex,
        ),
    };
  }

  PlaybackQueuesCompanion toQueueCompanion(PlaybackQueue queue) {
    return PlaybackQueuesCompanion.insert(
      id: queue.id.value,
      currentIndex: queue.currentIndex,
      repeatMode: queue.repeatMode,
      source: queue.source,
      shuffleEnabled: Value(queue.shuffleEnabled),
      preShuffleCurrentIndex: Value(queue.preShuffleCurrentIndex),
    );
  }

  /// Flattens BOTH the live order and, if shuffled, the pre-shuffle
  /// snapshot into insertable [QueueSongs] rows — see that table's
  /// class docs on why one physical table serves both lists.
  List<QueueSongsCompanion> toQueueSongCompanions(PlaybackQueue queue) {
    final rows = <QueueSongsCompanion>[];
    for (var i = 0; i < queue.songs.length; i++) {
      rows.add(QueueSongsCompanion.insert(
        queueId: queue.id.value,
        listKind: 'current',
        position: i,
        songId: queue.songs[i].id.value,
      ));
    }
    if (queue.shuffleEnabled && queue.preShuffleOrder != null) {
      final preShuffle = queue.preShuffleOrder!;
      for (var i = 0; i < preShuffle.length; i++) {
        rows.add(QueueSongsCompanion.insert(
          queueId: queue.id.value,
          listKind: 'preShuffle',
          position: i,
          songId: preShuffle[i].id.value,
        ));
      }
    }
    return rows;
  }
}
