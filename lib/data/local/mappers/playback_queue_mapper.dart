import 'package:drift/drift.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/playback_queue.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/value_objects/queue_id.dart';
import '../app_database.dart';

class PlaybackQueueMapper {
  const PlaybackQueueMapper();

  Result<PlaybackQueue, Failure> toEntity({
    required PlaybackQueueRow row,
    required List<Song> currentSongs,
    List<Song>? preShuffleSongs,
  }) {
    final savedPosition = Duration(milliseconds: row.positionMs);
    if (!row.shuffleEnabled) {
      return PlaybackQueue.create(
        id: QueueId(row.id),
        songs: currentSongs,
        currentIndex: row.currentIndex,
        repeatMode: row.repeatMode,
        source: row.source,
        position: savedPosition,
      );
    }

    final preShuffleResult = PlaybackQueue.create(
      id: QueueId(row.id),
      songs: preShuffleSongs ?? const [],
      currentIndex: row.preShuffleCurrentIndex ?? -1,
      repeatMode: row.repeatMode,
      source: row.source,
      position: savedPosition,
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
      positionMs: Value(queue.position.inMilliseconds),
    );
  }

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
