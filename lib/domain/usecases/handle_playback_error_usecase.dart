import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_queue.dart';
import '../repositories/audio_player_repository.dart';
import '../repositories/playback_repository.dart';
import '../value_objects/queue_id.dart';
import 'use_case.dart';

typedef HandlePlaybackErrorParams = ({
  QueueId queueId,
  PlaybackFailure error,
});

/// Reacts to a [PlaybackFailure] surfaced by the engine, implementing
/// RESILIENCIA's "decode errors skip to the next track automatically"
/// rule — while NOT auto-advancing for
/// [PlaybackFailureReason.engineError], where the same failure would
/// likely just repeat immediately on the next song too (see that
/// enum's own docs).
///
/// Duplicates a few lines of "advance + persist + load next" also
/// present in PlayQueueUseCase.skipNext, rather than depending on
/// that use case directly — Domain use cases in this app depend only
/// on repository interfaces, never on each other, so this small
/// overlap is the accepted cost of keeping that boundary clean.
///
/// Known limitation, deliberately not solved here: if MANY consecutive
/// songs fail to decode, this use case auto-skips through all of them
/// one at a time with no circuit breaker — tracking "N consecutive
/// failures" is inherently stateful across multiple invocations,
/// which doesn't fit a single stateless use case call. That belongs
/// to whichever Presentation-layer controller invokes this use case
/// repeatedly, once one exists.
final class HandlePlaybackErrorUseCase
    implements UseCase<PlaybackQueue?, HandlePlaybackErrorParams> {
  HandlePlaybackErrorUseCase(
    this._playbackRepository,
    this._audioPlayerRepository,
  );

  final PlaybackRepository _playbackRepository;
  final AudioPlayerRepository _audioPlayerRepository;

  @override
  Future<Result<PlaybackQueue?, Failure>> call(
    HandlePlaybackErrorParams params,
  ) async {
    if (params.error.reason != PlaybackFailureReason.decodeError) {
      // Engine-level errors are surfaced as-is; auto-retrying would
      // likely just fail again immediately.
      return Err(params.error);
    }

    final queueResult = await _playbackRepository.getQueue(params.queueId);
    return queueResult.asyncAndThen((queue) async {
      final advanced = queue.withAdvancedToNext();
      return advanced.asyncAndThen((newQueue) async {
        final saveResult = await _playbackRepository.saveQueue(newQueue);
        return saveResult.asyncAndThen((_) async {
          final nextSong = newQueue.currentSong;
          if (nextSong == null) return Ok(newQueue); // queue finished
          final loadResult = await _audioPlayerRepository.load(nextSong);
          return loadResult.asyncAndThen((_) async {
            final resumeResult = await _audioPlayerRepository.resume();
            return resumeResult.asyncAndThen((_) async => Ok(newQueue));
          });
        });
      });
    });
  }
}