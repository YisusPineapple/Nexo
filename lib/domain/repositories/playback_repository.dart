import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_queue.dart';
import '../entities/playback_settings.dart';
import '../value_objects/queue_id.dart';

/// A minimal snapshot of "what was playing and where", just enough to
/// restore position on app restart (REPRODUCCIÓN's "Recuperación de
/// posición al reiniciar la app"). Kept as a record rather than a new
/// entity: there's no identity or invariant here beyond what QueueId
/// and Duration already guarantee, so a dedicated class would just be
/// ceremony around two fields.
typedef ActiveSessionSnapshot = ({QueueId activeQueueId, Duration position});

/// Persistence and retrieval for playback state that isn't owned by any
/// single PlaybackQueue: the set of concurrent queues (1-5 per
/// REPRODUCCIÓN §2), engine-wide settings ([PlaybackSettings]), and the
/// last-active session for restart recovery.
///
/// Does NOT enforce the "max 5 concurrent queues" business rule — that
/// belongs to a future use case (e.g. CreateQueueUseCase), which can
/// call [getAllQueues] to check the current count before calling
/// [saveQueue]. This repository only persists what it's told; it isn't
/// where business rules live.
abstract interface class PlaybackRepository {
  /// Returns [NotFoundFailure] if no queue with [id] currently exists.
  Future<Result<PlaybackQueue, Failure>> getQueue(QueueId id);

  Future<Result<List<PlaybackQueue>, Failure>> getAllQueues();

  /// Upsert: creates the queue if [PlaybackQueue.id] is new, otherwise
  /// replaces the existing queue with that id.
  Future<Result<void, Failure>> saveQueue(PlaybackQueue queue);

  /// Returns [NotFoundFailure] if no queue with [id] exists. Deletion
  /// of an already-gone queue is treated as an error, not a silent
  /// no-op, so callers immediately notice a bug (e.g. two UI actions
  /// racing to close the same queue) rather than have it masked.
  Future<Result<void, Failure>> deleteQueue(QueueId id);

  Future<Result<PlaybackSettings, Failure>> getPlaybackSettings();

  Future<Result<void, Failure>> savePlaybackSettings(
    PlaybackSettings settings,
  );

  Future<Result<void, Failure>> saveActiveSession(
    ActiveSessionSnapshot snapshot,
  );

  /// Ok(null) — not a Failure — when there's no prior session (e.g.
  /// first launch after install). An absent session is an expected,
  /// normal state, unlike [NotFoundFailure]'s "this specific id should
  /// exist but doesn't".
  Future<Result<ActiveSessionSnapshot?, Failure>> getLastSession();
}