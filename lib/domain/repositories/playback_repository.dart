import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_queue.dart';
import '../entities/playback_settings.dart';
import '../value_objects/queue_id.dart';

typedef ActiveSessionSnapshot = ({QueueId activeQueueId, Duration position});

abstract interface class PlaybackRepository {
  Future<Result<PlaybackQueue, Failure>> getQueue(QueueId id);

  Future<Result<List<PlaybackQueue>, Failure>> getAllQueues();

  Future<Result<void, Failure>> saveQueue(PlaybackQueue queue);

  Future<Result<void, Failure>> updateQueuePosition(QueueId id, Duration position);

  Future<Result<void, Failure>> deleteQueue(QueueId id);

  Future<Result<PlaybackSettings, Failure>> getPlaybackSettings();

  Future<Result<void, Failure>> savePlaybackSettings(
    PlaybackSettings settings,
  );

  Future<Result<void, Failure>> saveActiveSession(
    ActiveSessionSnapshot snapshot,
  );

  Future<Result<ActiveSessionSnapshot?, Failure>> getLastSession();
}