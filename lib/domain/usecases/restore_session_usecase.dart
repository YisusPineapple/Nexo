import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_queue.dart';
import '../repositories/audio_player_repository.dart';
import '../repositories/playback_repository.dart';
import 'use_case.dart';

/// Restores the last active queue and playback position on app launch
/// (REPRODUCCIÓN's "Recuperación de posición al reiniciar la app").
/// Loads the engine to that exact position but deliberately does NOT
/// call resume() — surprising the user with audio the instant the app
/// opens would be worse than a silent, correctly-positioned player
/// waiting for an explicit play tap.
///
/// A missing OR stale session is treated as "nothing to restore"
/// (Ok(null)), not a Failure — first launch has no session at all,
/// and a session pointing at a since-deleted queue is a normal,
/// recoverable situation per this app's general resilience posture,
/// not a bug to surface as an error.
final class RestoreSessionUseCase
    implements UseCase<PlaybackQueue?, NoParams> {
  RestoreSessionUseCase(
    this._playbackRepository,
    this._audioPlayerRepository,
  );

  final PlaybackRepository _playbackRepository;
  final AudioPlayerRepository _audioPlayerRepository;

  @override
  Future<Result<PlaybackQueue?, Failure>> call(NoParams params) async {
    final sessionResult = await _playbackRepository.getLastSession();
    return sessionResult.asyncAndThen((snapshot) async {
      if (snapshot == null) return const Ok(null);

      final queueResult =
          await _playbackRepository.getQueue(snapshot.activeQueueId);
      return switch (queueResult) {
        Ok(value: final queue) => _loadPaused(queue, snapshot.position),
        Err(error: NotFoundFailure()) =>
          // Stale reference — the queue it pointed to is gone. Treat
          // as "nothing to restore" rather than propagating the
          // failure.
          const Ok(null),
        Err(error: final e) => Err(e),
      };
    });
  }

  Future<Result<PlaybackQueue?, Failure>> _loadPaused(
    PlaybackQueue queue,
    Duration position,
  ) async {
    final song = queue.currentSong;
    if (song == null) return Ok(queue);
    final loadResult =
        await _audioPlayerRepository.load(song, startAt: position);
    return loadResult.asyncAndThen((_) async => Ok(queue));
  }
}