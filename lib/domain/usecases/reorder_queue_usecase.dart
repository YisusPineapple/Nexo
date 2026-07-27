import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_queue.dart';
import '../repositories/playback_repository.dart';
import '../value_objects/queue_id.dart';
import 'use_case.dart';

typedef ReorderQueueParams = ({
  QueueId queueId,
  int oldIndex,
  int newIndex,
});

/// Drag-to-reorder a song within a queue (REPRODUCCIÓN's
/// ReorderableListView requirement). Thin orchestration only — the
/// actual reorder logic, including staying correct with duplicate
/// songs, already lives in [PlaybackQueue.withSongMoved]; this use
/// case just fetches, delegates, and persists.
final class ReorderQueueUseCase
    implements UseCase<PlaybackQueue, ReorderQueueParams> {
  ReorderQueueUseCase(this._playbackRepository);

  final PlaybackRepository _playbackRepository;

  @override
  Future<Result<PlaybackQueue, Failure>> call(
    ReorderQueueParams params,
  ) async {
    final queueResult = await _playbackRepository.getQueue(params.queueId);
    return queueResult.asyncAndThen((queue) async {
      final moved = queue.withSongMoved(
        oldIndex: params.oldIndex,
        newIndex: params.newIndex,
      );
      return moved.asyncAndThen((newQueue) async {
        final saveResult = await _playbackRepository.saveQueue(newQueue);
        return saveResult.asyncAndThen((_) async => Ok(newQueue));
      });
    });
  }
}
