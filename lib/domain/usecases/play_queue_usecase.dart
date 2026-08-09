import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_queue.dart';
import '../entities/song.dart';
import '../repositories/audio_player_repository.dart';
import '../repositories/playback_repository.dart';
import '../value_objects/queue_id.dart';

/// Controls playback of whichever queue is currently active: play,
/// pause, skip forward/backward, and seek.
///
/// Deliberately does NOT implement `UseCase<T,P>` like the other five
/// — per SOLID estricto this needs justifying: play/pause/skip/seek
/// all mutate the SAME piece of cohesive state (what's currently
/// loaded in the engine, and which queue/index that corresponds to),
/// the way a single remote control has several buttons for one
/// device. Splitting them into five single-method use case classes
/// wouldn't add isolation — they'd all need the exact same two
/// repository dependencies and would constantly call into each
/// other's logic (e.g. skipNext re-deriving what play already knows
/// about loading a song) — it would just scatter one responsibility
/// across five files.
final class PlayQueueUseCase {
  PlayQueueUseCase(this._playbackRepository, this._audioPlayerRepository);

  final PlaybackRepository _playbackRepository;
  final AudioPlayerRepository _audioPlayerRepository;

  /// Starts (or restarts) playback of [queueId]'s current song from
  /// the beginning.
  Future<Result<void, Failure>> play(QueueId queueId) async {
    final queueResult = await _playbackRepository.getQueue(queueId);
    return queueResult.asyncAndThen((queue) async {
      final song = queue.currentSong;
      if (song == null) {
        return Err(ValidationFailure(
          'Cannot play queue "${queueId.value}": it has no current song.',
        ));
      }
      return _loadAndResume(song);
    });
  }

  Future<Result<void, Failure>> pause() => _audioPlayerRepository.pause();

  /// Advances [queueId] per [PlaybackQueue.withAdvancedToNext],
  /// persists the new state, and starts playing the new current song
  /// — unless the queue just reached its natural end (see that
  /// method's docs on RepeatMode.off), in which case nothing is
  /// loaded and playback simply stops.
  Future<Result<PlaybackQueue, Failure>> skipNext(QueueId queueId) {
    return _advance(queueId, (queue) => queue.withAdvancedToNext());
  }

  Future<Result<PlaybackQueue, Failure>> skipPrevious(QueueId queueId) {
    return _advance(queueId, (queue) => queue.withAdvancedToPrevious());
  }

  Future<Result<void, Failure>> seekTo(Duration position) =>
      _audioPlayerRepository.seekTo(position);

  Future<Result<PlaybackQueue, Failure>> _advance(
    QueueId queueId,
    Result<PlaybackQueue, Failure> Function(PlaybackQueue queue) advance,
  ) async {
    final queueResult = await _playbackRepository.getQueue(queueId);
    return queueResult.asyncAndThen((queue) async {
      final advanced = advance(queue);
      return advanced.asyncAndThen((newQueue) async {
        final saveResult = await _playbackRepository.saveQueue(newQueue);
        return saveResult.asyncAndThen((_) async {
          // Sync the updated queue to the audio handler
          final syncResult = await _audioPlayerRepository.updateQueue(
            newQueue.songs,
            currentIndex: newQueue.currentIndex,
          );
          return syncResult.asyncAndThen((_) async {
            final nextSong = newQueue.currentSong;
            if (nextSong == null) {
              // Queue reached its natural end — stopping is the correct
              // outcome here, not a Failure.
              return Ok(newQueue);
            }
            final loadResult = await _loadAndResume(nextSong);
            return loadResult.asyncAndThen((_) async => Ok(newQueue));
          });
        });
      });
    });
  }

  Future<Result<void, Failure>> _loadAndResume(Song song) async {
    final loadResult = await _audioPlayerRepository.load(song);
    return loadResult.asyncAndThen((_) => _audioPlayerRepository.resume());
  }
}
