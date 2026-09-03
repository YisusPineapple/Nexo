import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_queue.dart';
import '../repositories/audio_player_repository.dart';
import '../repositories/playback_repository.dart';
import '../value_objects/queue_id.dart';

typedef OpenQueueParams = ({PlaybackQueue queue, bool asNewTab});

final class OpenQueueUseCase {
  OpenQueueUseCase(this._playbackRepo, this._audioRepo);
  final PlaybackRepository _playbackRepo;
  final AudioPlayerRepository _audioRepo;

  Future<Result<void, Failure>> call(OpenQueueParams params) async {
    var queueToOpen = params.queue;

    if (params.asNewTab) {
      final queuesResult = await _playbackRepo.getAllQueues();
      if (queuesResult.isErr) {
        return Err(
            queuesResult.when(ok: (_) => throw Exception(), err: (e) => e));
      }

      final existingQueues = queuesResult.valueOrNull!;
      final isExisting = existingQueues.any((q) => q.id == queueToOpen.id);

      if (!isExisting && existingQueues.length >= maxConcurrentQueues) {
        return const Err(ValidationFailure(
            'Maximum concurrent queues limit reached (5). Please close one first.'));
      }
    } else {
      final lastSessionResult = await _playbackRepo.getLastSession();
      final activeQueueId = lastSessionResult.valueOrNull?.activeQueueId;
      if (activeQueueId != null) {
        queueToOpen = queueToOpen.withId(activeQueueId);
      }
    }

    final saveResult = await _playbackRepo.saveQueue(queueToOpen);
    if (saveResult.isErr) {
      return saveResult;
    }

    final sessionResult = await _playbackRepo.saveActiveSession((
      activeQueueId: queueToOpen.id,
      position: queueToOpen.position,
    ));
    if (sessionResult.isErr) {
      return sessionResult;
    }

    return _audioRepo.updateQueue(
      queueToOpen.songs,
      currentIndex: queueToOpen.currentIndex,
      repeatMode: queueToOpen.repeatMode,
    );
  }
}

final class SwitchQueueUseCase {
  SwitchQueueUseCase(this._playbackRepo, this._audioRepo);
  final PlaybackRepository _playbackRepo;
  final AudioPlayerRepository _audioRepo;

  Future<Result<PlaybackQueue, Failure>> call(QueueId targetQueueId) async {
    final queueResult = await _playbackRepo.getQueue(targetQueueId);
    return queueResult.asyncAndThen((queue) async {
      final sessionResult = await _playbackRepo.saveActiveSession((
        activeQueueId: queue.id,
        position: queue.position,
      ));
      return sessionResult.asyncAndThen((_) async {
        final syncResult = await _audioRepo.updateQueue(
          queue.songs,
          currentIndex: queue.currentIndex,
          repeatMode: queue.repeatMode,
        );
        return syncResult.asyncAndThen((_) async {
          final song = queue.currentSong;
          if (song != null) {
            await _audioRepo.seekTo(queue.position);
            await _audioRepo.pause();
            return Ok(queue);
          }
          await _audioRepo.stop();
          return Ok(queue);
        });
      });
    });
  }
}

typedef CloseQueueParams = ({QueueId queueIdToClose, QueueId? activeQueueId});

final class CloseQueueUseCase {
  CloseQueueUseCase(this._playbackRepo, this._audioRepo);
  final PlaybackRepository _playbackRepo;
  final AudioPlayerRepository _audioRepo;

  Future<Result<PlaybackQueue?, Failure>> call(CloseQueueParams params) async {
    final deleteResult = await _playbackRepo.deleteQueue(params.queueIdToClose);
    if (deleteResult.isErr) {
      return Err(
          deleteResult.when(ok: (_) => throw Exception(), err: (e) => e));
    }

    if (params.queueIdToClose == params.activeQueueId) {
      final queuesResult = await _playbackRepo.getAllQueues();
      if (queuesResult.isErr) {
        return Err(
            queuesResult.when(ok: (_) => throw Exception(), err: (e) => e));
      }

      final remainingQueues = queuesResult.valueOrNull!;
      if (remainingQueues.isNotEmpty) {
        final nextQueue = remainingQueues.last;
        final switchUseCase = SwitchQueueUseCase(_playbackRepo, _audioRepo);
        final switchResult = await switchUseCase.call(nextQueue.id);
        return switchResult.map((q) => q);
      } else {
        await _playbackRepo.clearActiveSession();
        await _audioRepo.stop();
        return const Ok(null);
      }
    }
    return const Ok(null);
  }
}
