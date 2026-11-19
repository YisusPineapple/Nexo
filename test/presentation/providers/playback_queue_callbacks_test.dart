import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/core/utils/result.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/repeat_mode.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/queue_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';
import 'package:nexo/presentation/providers/playback_queue_callbacks.dart';
import 'package:nexo/presentation/providers/serialized_task_queue.dart';

Song _song(int id) {
  return Song.create(
    id: SongId(id),
    title: 'Title $id',
    trackArtistId: const ArtistId('artist-1'),
    duration: const Duration(minutes: 3),
    filePath: '/music/$id.mp3',
    format: AudioFormat.mp3,
    fileSizeBytes: 1000,
    dateAddedUtc: DateTime.utc(2026, 1, 1),
  ).valueOrNull!;
}

PlaybackQueue _queue({
  required int songCount,
  required int currentIndex,
  RepeatMode repeatMode = RepeatMode.off,
}) {
  return PlaybackQueue.create(
    id: const QueueId('q1'),
    songs: List.generate(songCount, (i) => _song(i + 1)),
    currentIndex: currentIndex,
    repeatMode: repeatMode,
    source: const ManualQueueSource(),
  ).valueOrNull!;
}

/// In-memory harness around [PlaybackQueueCallbacks]. The serializer is
/// exposed so tests can append a no-op barrier task: FIFO guarantees it
/// completes only after every previously enqueued callback task ran.
class _Harness {
  _Harness(PlaybackQueue? initial) : current = initial {
    callbacks = PlaybackQueueCallbacks(
      readQueue: () => current,
      writeQueue: (queue) {
        current = queue;
        writes.add(queue);
      },
      saveQueue: (queue) async {
        saves.add(queue);
        saveStarted = true;
        final gate = saveGate;
        if (gate != null) {
          await gate.future;
        }
        return const Ok(null);
      },
      stopEngine: () async {
        stops++;
        return const Ok(null);
      },
      serializer: serializer,
    );
  }

  PlaybackQueue? current;
  late final PlaybackQueueCallbacks callbacks;
  final SerializedTaskQueue serializer = SerializedTaskQueue();
  final List<PlaybackQueue> writes = [];
  final List<PlaybackQueue> saves = [];
  int stops = 0;
  bool saveStarted = false;
  Completer<void>? saveGate;

  Future<void> settle() => serializer.enqueue(() async {});
}

void main() {
  group('PlaybackQueueCallbacks — happy path', () {
    test('advanced commits the new index and persists it', () async {
      final h = _Harness(_queue(songCount: 3, currentIndex: 0));
      h.callbacks.onAdvanced(1);
      await h.settle();
      expect(h.current!.currentIndex, 1);
      expect(h.saves.single.currentIndex, 1);
      expect(h.stops, 0);
    });

    test('ended on the last track finishes the queue and stops once', () async {
      final h = _Harness(_queue(songCount: 2, currentIndex: 1));
      h.callbacks.onEnded();
      await h.settle();
      expect(h.current!.currentIndex, -1);
      expect(h.saves.single.currentIndex, -1);
      expect(h.stops, 1);
    });
  });

  group('PlaybackQueueCallbacks — F1 regression (phantom track 1)', () {
    test('double ended is idempotent: a finished queue never wraps to 0',
        () async {
      final h = _Harness(_queue(songCount: 2, currentIndex: 1));
      h.callbacks.onEnded();
      await h.settle();
      expect(h.current!.currentIndex, -1);
      final savesAfterFirst = h.saves.length;

      // Second engine ended event (stale completion or media-button
      // Next in the pre-teardown window). Pre-fix, this read the
      // finished queue and withAdvancedToNext() wrapped it to 0,
      // persisting a paused phantom track 1 with the engine stopped.
      h.callbacks.onEnded();
      await h.settle();
      expect(h.current!.currentIndex, -1,
          reason: 'A second ended event must be a no-op on a finished '
              'queue. currentIndex 0 here is the exact F1 phantom.');
      expect(h.saves.length, savesAfterFirst);
      expect(h.stops, 1);
    });

    test('advanced on a finished queue is dropped', () async {
      final h = _Harness(_queue(songCount: 2, currentIndex: 1));
      h.callbacks.onEnded();
      await h.settle();
      final savesAfterEnd = h.saves.length;

      h.callbacks.onAdvanced(0);
      await h.settle();
      expect(h.current!.currentIndex, -1,
          reason: 'A stale advanced event must not resurrect a finished '
              'queue via withCurrentIndex.');
      expect(h.saves.length, savesAfterEnd);
    });

    test('ended commits state BEFORE persistence completes', () async {
      final h = _Harness(_queue(songCount: 2, currentIndex: 1));
      h.saveGate = Completer<void>();

      h.callbacks.onEnded();
      await pumpEventQueue();

      expect(h.saveStarted, isTrue);
      expect(h.current!.currentIndex, -1,
          reason: 'State must be committed synchronously before the '
              'awaited save, so any event reading state during the '
              'save window sees the finished queue, not the stale one.');
      expect(h.stops, 0, reason: 'stop waits for the save to land');

      h.saveGate!.complete();
      await h.settle();
      expect(h.stops, 1);
    });

    test(
        'advanced enqueued before ended commits first (shared FIFO) — '
        'no paused phantom at the last track', () async {
      final h = _Harness(_queue(songCount: 3, currentIndex: 1));
      h.saveGate = Completer<void>();

      h.callbacks.onAdvanced(2);
      await pumpEventQueue();
      expect(h.saveStarted, isTrue);
      expect(h.current!.currentIndex, 2);

      // Ended arrives while the advanced save is still in flight.
      // Pre-fix, ended ran unserialized: it read the stale index 1,
      // advanced to 2 (not finished!), and stopped the engine — then
      // the advanced task committed index 2, leaving a visible paused
      // track 3 with a dead engine.
      h.callbacks.onEnded();
      await pumpEventQueue();
      expect(h.stops, 0,
          reason: 'ended must wait for the in-flight advanced task');

      h.saveGate!.complete();
      await h.settle();
      expect(h.current!.currentIndex, -1,
          reason: 'FIFO: advanced commits 2, then ended reads 2 and '
              'finishes the queue. Any other final index means the '
              'callbacks were not serialized together.');
      expect(h.saves.map((q) => q.currentIndex).toList(), [2, -1]);
      expect(h.stops, 1);
    });
  });

  group('PlaybackQueueCallbacks — null state', () {
    test('ended with no active queue is a no-op', () async {
      final h = _Harness(null);
      h.callbacks.onEnded();
      await h.settle();
      expect(h.writes, isEmpty);
      expect(h.saves, isEmpty);
      expect(h.stops, 0);
    });

    test('advanced with no active queue is a no-op', () async {
      final h = _Harness(null);
      h.callbacks.onAdvanced(0);
      await h.settle();
      expect(h.writes, isEmpty);
      expect(h.saves, isEmpty);
    });
  });
}
