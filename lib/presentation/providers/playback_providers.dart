import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/playback_queue.dart';
import '../../domain/entities/queue_source.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../domain/entities/song.dart';
import '../../domain/usecases/multi_queue_usecases.dart';
import '../../domain/usecases/play_queue_usecase.dart';
import '../../domain/usecases/reorder_queue_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/shuffle_queue_usecase.dart';
import '../../domain/usecases/use_case.dart';
import '../../domain/usecases/user_metrics_usecases.dart';
import '../../domain/value_objects/queue_id.dart';
import 'app_preferences_provider.dart';
import 'for_you_provider.dart';
import 'queue_manager_provider.dart';
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

final sleepTimerProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioPlayerRepositoryProvider).sleepTimerStream;
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

    handler.onQueueAdvanced = (newIndex) async {
      final currentQueue = state.valueOrNull;
      if (currentQueue == null) {
        return;
      }

      final updated = currentQueue.withCurrentIndex(newIndex);
      if (updated.isOk) {
        final newQueue = updated.valueOrNull!;
        await ref.read(playbackRepositoryProvider).saveQueue(newQueue);
        state = AsyncData(newQueue);
      }
    };

    handler.onQueueEnded = () async {
      final currentQueue = state.valueOrNull;
      if (currentQueue == null) {
        return;
      }

      final updated = currentQueue.withCurrentIndex(0);
      if (updated.isOk) {
        final newQueue = updated.valueOrNull!;
        await ref.read(playbackRepositoryProvider).saveQueue(newQueue);
        state = AsyncData(newQueue);

        final repo = ref.read(audioPlayerRepositoryProvider);
        await repo.updateQueue(
          newQueue.songs,
          currentIndex: 0,
          repeatMode: newQueue.repeatMode,
        );
        await repo.pause();
        await repo.seekTo(Duration.zero);
      }
    };

    ref.listen(
      StreamProvider(
          (ref) => ref.watch(audioPlayerRepositoryProvider).completedStream),
      (_, next) {
        if (next.hasValue && state.valueOrNull != null) {
          final currentSong = state.valueOrNull!.currentSong;
          if (currentSong != null) {
            final logUseCase =
                LogSongPlayUseCase(ref.read(userMetricsRepositoryProvider));
            logUseCase.call(currentSong.id);
            ref.invalidate(forYouControllerProvider);
          }
        }
      },
    );

    ref.listen(
      appPreferencesProvider.select((prefs) => prefs.performanceProfile),
      (prev, next) {
        ref.read(audioPlayerRepositoryProvider).setPerformanceProfile(next);
      },
      fireImmediately: true,
    );

    if (queue != null) {
      await ref.read(audioPlayerRepositoryProvider).updateQueue(
            queue.songs,
            currentIndex: queue.currentIndex,
            repeatMode: queue.repeatMode,
          );
    }

    final timer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final isPlaying = ref.read(playingStreamProvider).valueOrNull ?? false;
      final currentQueue = state.valueOrNull;

      if (isPlaying && currentQueue != null) {
        final pos =
            ref.read(positionStreamProvider).valueOrNull ?? Duration.zero;
        final repo = ref.read(playbackRepositoryProvider);
        await repo.updateQueuePosition(currentQueue.id, pos);
        await repo.saveActiveSession((
          activeQueueId: currentQueue.id,
          position: pos,
        ));
      }
    });

    ref.onDispose(() {
      timer.cancel();
    });

    return queue;
  }

  Future<void> _setQueueState(PlaybackQueue queue) async {
    state = AsyncData(queue);
    await ref.read(audioPlayerRepositoryProvider).updateQueue(
          queue.songs,
          currentIndex: queue.currentIndex,
          repeatMode: queue.repeatMode,
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

  Future<String?> playSongs({
    required String queueIdStr,
    required List<Song> songs,
    required int startIndex,
    required QueueSource source,
    bool openAsNewTab = false,
  }) async {
    final queueId = QueueId(queueIdStr);
    final queueResult = PlaybackQueue.create(
      id: queueId,
      songs: songs,
      currentIndex: startIndex,
      source: source,
    );

    if (queueResult.isErr) {
      return queueResult.when(ok: (_) => null, err: (e) => e.message);
    }

    final useCase = OpenQueueUseCase(
      ref.read(playbackRepositoryProvider),
      ref.read(audioPlayerRepositoryProvider),
    );

    final result = await useCase.call((
      queue: queueResult.valueOrNull!,
      asNewTab: openAsNewTab,
    ));

    if (result.isErr) {
      return result.when(ok: (_) => null, err: (e) => e.message);
    }

    // FIX: Read effective queue ID from active session to handle overwrite properly
    final sessionResult =
        await ref.read(playbackRepositoryProvider).getLastSession();
    final effectiveQueueId =
        sessionResult.valueOrNull?.activeQueueId ?? queueId;

    ref.invalidate(queueManagerControllerProvider);
    await playQueue(effectiveQueueId);
    return null;
  }

  Future<void> switchQueue(QueueId id) async {
    final useCase = SwitchQueueUseCase(
      ref.read(playbackRepositoryProvider),
      ref.read(audioPlayerRepositoryProvider),
    );

    final result = await useCase.call(id);
    if (result.isOk) {
      state = AsyncData(result.valueOrNull!);
      ref.invalidate(queueManagerControllerProvider);
    }
  }

  Future<void> closeQueue(QueueId id) async {
    final currentQueue = state.valueOrNull;
    final useCase = CloseQueueUseCase(
      ref.read(playbackRepositoryProvider),
      ref.read(audioPlayerRepositoryProvider),
    );

    final result = await useCase.call((
      queueIdToClose: id,
      activeQueueId: currentQueue?.id,
    ));

    if (result.isOk) {
      final newActiveQueue = result.valueOrNull;
      if (currentQueue?.id == id) {
        state = AsyncData(newActiveQueue);
      }
      ref.invalidate(queueManagerControllerProvider);
    }
  }

  Future<void> addSongNext(Song song) async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) {
      return;
    }

    final updated = currentQueue.withSongAddedNext(song);
    if (updated.isOk) {
      final newQueue = updated.valueOrNull!;
      await ref.read(playbackRepositoryProvider).saveQueue(newQueue);
      await _setQueueState(newQueue);
    }
  }

  Future<void> addSongLast(Song song) async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) {
      return;
    }

    final updated = currentQueue.withSongAddedLast(song);
    if (updated.isOk) {
      final newQueue = updated.valueOrNull!;
      await ref.read(playbackRepositoryProvider).saveQueue(newQueue);
      await _setQueueState(newQueue);
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
    if (currentQueue == null) {
      return;
    }
    await ref.read(audioPlayerRepositoryProvider).advanceToNext();
  }

  Future<void> skipPrevious() async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) {
      return;
    }
    await ref.read(audioPlayerRepositoryProvider).advanceToPrevious();
  }

  Future<void> skipToIndex(int index) async {
    final currentQueue = state.valueOrNull;
    if (currentQueue == null) {
      return;
    }

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
    if (currentQueue == null) {
      return;
    }

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
    if (currentQueue == null) {
      return;
    }

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
    if (currentQueue == null) {
      return;
    }

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

  Future<void> setSleepTimer(Duration? duration) async {
    await ref.read(audioPlayerRepositoryProvider).setSleepTimer(duration);
  }

  Future<void> stop() async {
    await ref.read(audioPlayerRepositoryProvider).stop();
    state = const AsyncData(null);
  }
}
