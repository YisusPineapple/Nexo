import 'dart:async';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/playback_queue.dart';
import 'serialized_task_queue.dart';

/// Applies engine queue callbacks (advanced / ended) to the playback
/// controller's queue state.
///
/// Contract (audit decisions §10.1 and §10.3):
/// - BOTH callbacks run through the SAME [SerializedTaskQueue], so an
///   `advanced` event enqueued before `ended` can never commit after it
///   (FIFO). Without this, a stale `advanced` landing on a finished
///   queue would resurrect a paused phantom track.
/// - `ended` is idempotent: a queue already finished (currentIndex -1)
///   is never advanced again. The domain's wrap-to-0 semantics from a
///   finished queue are reserved for explicit user actions, not engine
///   events (F1 — the "phantom track 1" regression).
/// - `advanced` on a finished queue is dropped (stale-event guard).
/// - State is committed synchronously BEFORE awaiting persistence, so
///   any second event reading state during the save window sees the
///   new value, never the stale one. The engine never awaits these
///   callbacks (§10.3); persistence stays best-effort here — the Err
///   logging policy lands separately (audit Fix 5).
///
/// This class deliberately holds no Riverpod or audio-handler types:
/// the controller injects plain functions, which makes the exact F1
/// event sequences unit-testable without native just_audio players.
class PlaybackQueueCallbacks {
  PlaybackQueueCallbacks({
    required PlaybackQueue? Function() readQueue,
    required void Function(PlaybackQueue queue) writeQueue,
    required Future<Result<void, Failure>> Function(PlaybackQueue queue)
        saveQueue,
    required Future<Result<void, Failure>> Function() stopEngine,
    SerializedTaskQueue? serializer,
  })  : _readQueue = readQueue,
        _writeQueue = writeQueue,
        _saveQueue = saveQueue,
        _stopEngine = stopEngine,
        _serializer = serializer ?? SerializedTaskQueue();

  final PlaybackQueue? Function() _readQueue;
  final void Function(PlaybackQueue queue) _writeQueue;
  final Future<Result<void, Failure>> Function(PlaybackQueue queue) _saveQueue;
  final Future<Result<void, Failure>> Function() _stopEngine;
  final SerializedTaskQueue _serializer;

  void onAdvanced(int newIndex) {
    unawaited(_serializer.enqueue(() async {
      final currentQueue = _readQueue();
      if (currentQueue == null || currentQueue.currentIndex < 0) {
        return;
      }
      final updated = currentQueue.withCurrentIndex(newIndex);
      if (updated.isOk) {
        final newQueue = updated.valueOrNull!;
        _writeQueue(newQueue);
        await _saveQueue(newQueue);
      }
    }));
  }

  void onEnded() {
    unawaited(_serializer.enqueue(() async {
      final currentQueue = _readQueue();
      if (currentQueue == null || currentQueue.currentIndex < 0) {
        return;
      }
      // Respect the domain model: withAdvancedToNext() yields
      // currentIndex -1 when the last track ends with RepeatMode.off.
      final updated = currentQueue.withAdvancedToNext();
      if (updated.isOk) {
        final newQueue = updated.valueOrNull!;
        _writeQueue(newQueue);
        await _saveQueue(newQueue);
        // The queue is finished. Stop the engine cleanly so the
        // notification and media session are torn down.
        await _stopEngine();
      }
    }));
  }
}
