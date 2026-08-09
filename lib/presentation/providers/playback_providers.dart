import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/playback_queue.dart';
import '../../domain/entities/queue_source.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../domain/entities/song.dart';
import '../../domain/usecases/play_queue_usecase.dart';
import '../../domain/usecases/reorder_queue_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/shuffle_queue_usecase.dart';
import '../../domain/usecases/use_case.dart';
import '../../domain/value_objects/queue_id.dart';
import 'repository_providers.dart';

final positionStreamProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioPlayerRepositoryProvider).positionStream;
});

final durationStreamProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioPlayerRepositoryProvider).durationStream;
});

final playingStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(audioPlayerRepositoryProvider).playingStream;
});

final playbackControllerProvider =
    AsyncNotifierProvider<PlaybackController, PlaybackQueue?>(
  PlaybackController.new,
);

class PlaybackController extends AsyncNotifier<PlaybackQueue?> {
  @override
  Future<PlaybackQueue?> build() async {
    final restoreUseCase = RestoreSessionUseCase(
      ref.watch(playbackRepositoryProvider),
      ref.watch(audioPlayerRepositoryProvider),
    );

    final result = await restoreUseCase.call(const NoParams());
    final queue = result.valueOrNull;

    final handler = ref.read(audioHandlerProvider);

    // Callback for when the engine advances automatically (via crossfade or natural end)
    handler.onQueueAdvanced = (newIndex) async {
      final currentQueue = state.valueOrNull;
      if (currentQueue == null) return;

      // Update the current queue index and persist the new state.
      final updated = currentQueue.withCurrentIndex(newIndex);
      if (updated.isOk) {
        final newQueue = updated.valueOrNull!;
        await ref.read(playbackRepositoryProvider).saveQueue(newQueue);
        state = AsyncData(newQueue);
      }
    };

    handler.onQueueEnded = () {
      state = const AsyncData(null);
    };

    if (queue != null) {
      await ref.read(audioPlayerRepositoryProvider).updateQueue(
            queue.songs,
            currentIndex: queue.currentIndex,
          );
    }

    return queue;
  }

  Future<void> _setQueueState(PlaybackQueue queue) async {
    state = AsyncData(queue);
    await ref.read(audioPlayerRepositoryProvider).updateQueue(
          queue.songs,
          currentIndex: queue.currentIndex,
        );
  }

  Future<void> playQueue(QueueId queueId) async {
    final useCase = PlayQueueUseCase(
      ref.read(playbackRepositoryProvider),
      ref.read(audioPlayerRepositoryProvider),
    );

    final result = await useCase.play(queueId);
    if (result.isOk) {
      final queueResult =
          await ref.read(playbackRepositoryProvider).getQueue(queueId);
      if (queueResult.isOk) {
        await _setQueueState(queueResult.valueOrNull!);
      }
    }
  }

  Future<void> playSongs({
    required String queueIdStr,
    required List<Song> songs,
    required int startIndex,
    required QueueSource source,
  }) async {
    final queueId = QueueId(queueIdStr);
    final queueResult = PlaybackQueue.create(
      id: queueId,
      songs: songs,
      currentIndex: startIndex,
      source: source,
    );

    if (queueResult.isOk) {
      await ref
          .read(playbackRepositoryProvider)
          .saveQueue(queueResult.valueOrNull!);
      await playQueue(queueId);
    }
  }

  Future<void> togglePlayPause() async {
    final isPlaying = ref.read(playingStreamProvider).valueOrNull ?? false;
    final repo = ref.read(audioPlayerRepositoryProvider);
    if (isPlaying) {
      await repo.pause();
    } else {
      await repo.resume();
    }
  }

  Future<void> skipNext() async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) return;
    // The engine will advance internally. onQueueAdvanced will update the state.
    await ref.read(audioPlayerRepositoryProvider).advanceToNext();
  }

  Future<void> skipPrevious() async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) return;

    final useCase = PlayQueueUseCase(
      ref.read(playbackRepositoryProvider),
      ref.read(audioPlayerRepositoryProvider),
    );

    final result = await useCase.skipPrevious(currentQueue.id);
    if (result.isOk) {
      await _setQueueState(result.valueOrNull!);
    }
  }

  Future<void> skipToIndex(int index) async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) return;

    final updated = currentQueue.withCurrentIndex(index);
    if (updated.isOk) {
      await ref
          .read(playbackRepositoryProvider)
          .saveQueue(updated.valueOrNull!);
      await playQueue(currentQueue.id);
    }
  }

  Future<void> seekTo(Duration position) async {
    await ref.read(audioPlayerRepositoryProvider).seekTo(position);
  }

  Future<void> toggleShuffle() async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) return;

    final useCase = ShuffleQueueUseCase(ref.read(playbackRepositoryProvider));
    final result = await useCase.call((
      queueId: currentQueue.id,
      enable: !currentQueue.shuffleEnabled,
    ));

    if (result.isOk) {
      await _setQueueState(result.valueOrNull!);
    }
  }

  Future<void> toggleRepeatMode() async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) return;

    final nextMode = switch (currentQueue.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };

    final updated = currentQueue.withRepeatMode(nextMode);
    await ref.read(playbackRepositoryProvider).saveQueue(updated);
    await _setQueueState(updated);
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final useCase = ReorderQueueUseCase(ref.read(playbackRepositoryProvider));
    final result = await useCase.call((
      queueId: currentQueue.id,
      oldIndex: oldIndex,
      newIndex: newIndex,
    ));

    if (result.isOk) {
      await _setQueueState(result.valueOrNull!);
    }
  }
}
