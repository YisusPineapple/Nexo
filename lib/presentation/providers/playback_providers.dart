import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/playback_queue.dart';
import '../../domain/entities/queue_source.dart';
import '../../domain/entities/song.dart';
import '../../domain/usecases/play_queue_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
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

    // Listen for track completion to auto-advance
    ref.listen(
      StreamProvider((ref) => ref.watch(audioPlayerRepositoryProvider).completedStream),
      (_, next) {
        if (next.hasValue && state.valueOrNull != null) {
          skipNext();
        }
      },
    );

    return result.valueOrNull;
  }

  Future<void> playQueue(QueueId queueId) async {
    final useCase = PlayQueueUseCase(
      ref.read(playbackRepositoryProvider),
      ref.read(audioPlayerRepositoryProvider),
    );
    
    final result = await useCase.play(queueId);
    if (result.isOk) {
      final queueResult = await ref.read(playbackRepositoryProvider).getQueue(queueId);
      state = AsyncData(queueResult.valueOrNull);
    }
  }

  /// Helper to create a queue on the fly and play it (e.g. tapping a song in a list)
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
      await ref.read(playbackRepositoryProvider).saveQueue(queueResult.valueOrNull!);
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

    final useCase = PlayQueueUseCase(
      ref.read(playbackRepositoryProvider),
      ref.read(audioPlayerRepositoryProvider),
    );
    
    final result = await useCase.skipNext(currentQueue.id);
    if (result.isOk) {
      state = AsyncData(result.valueOrNull);
    }
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
      state = AsyncData(result.valueOrNull);
    }
  }

  Future<void> seekTo(Duration position) async {
    await ref.read(audioPlayerRepositoryProvider).seekTo(position);
  }
}