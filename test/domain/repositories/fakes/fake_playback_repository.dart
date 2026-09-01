import 'package:nexo/core/error/failures.dart';
import 'package:nexo/core/utils/result.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/playback_settings.dart';
import 'package:nexo/domain/repositories/playback_repository.dart';
import 'package:nexo/domain/value_objects/queue_id.dart';

class FakePlaybackRepository implements PlaybackRepository {
  FakePlaybackRepository({
    List<PlaybackQueue> initialQueues = const [],
    PlaybackSettings initialSettings = PlaybackSettings.defaults,
  })  : _queues = {for (final q in initialQueues) q.id: q},
        _settings = initialSettings;

  final Map<QueueId, PlaybackQueue> _queues;
  PlaybackSettings _settings;
  ActiveSessionSnapshot? _lastSession;

  @override
  Future<Result<PlaybackQueue, Failure>> getQueue(QueueId id) async {
    final queue = _queues[id];
    if (queue == null) {
      return Err(NotFoundFailure('No queue found with id "${id.value}".'));
    }
    return Ok(queue);
  }

  @override
  Future<Result<List<PlaybackQueue>, Failure>> getAllQueues() async {
    return Ok(List.unmodifiable(_queues.values));
  }

  @override
  Future<Result<void, Failure>> saveQueue(PlaybackQueue queue) async {
    _queues[queue.id] = queue;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> updateQueuePosition(
    QueueId id,
    Duration position,
  ) async {
    final queue = _queues[id];
    if (queue == null) {
      return Err(NotFoundFailure('No queue found with id "${id.value}".'));
    }
    _queues[id] = queue.withPosition(position).valueOrNull!;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> deleteQueue(QueueId id) async {
    if (!_queues.containsKey(id)) {
      return Err(NotFoundFailure('No queue found with id "${id.value}".'));
    }
    _queues.remove(id);
    return const Ok(null);
  }

  @override
  Future<Result<PlaybackSettings, Failure>> getPlaybackSettings() async {
    return Ok(_settings);
  }

  @override
  Future<Result<void, Failure>> savePlaybackSettings(
    PlaybackSettings settings,
  ) async {
    _settings = settings;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> saveActiveSession(
    ActiveSessionSnapshot snapshot,
  ) async {
    _lastSession = snapshot;
    return const Ok(null);
  }

  @override
  Future<Result<ActiveSessionSnapshot?, Failure>> getLastSession() async {
    return Ok(_lastSession);
  }

  @override
  Future<Result<void, Failure>> clearActiveSession() async {
    _lastSession = null;
    return const Ok(null);
  }
}
