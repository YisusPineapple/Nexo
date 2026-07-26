import 'dart:math';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_queue.dart';
import '../repositories/playback_repository.dart';
import '../value_objects/queue_id.dart';
import 'use_case.dart';

typedef ShuffleQueueParams = ({QueueId queueId, bool enable});

/// Toggles true shuffle on a queue (REPRODUCCIÓN §2: shuffles the
/// ENTIRE queue order once, not per-song re-randomization on every
/// track change).
///
/// Owns the actual permutation and RNG — deliberately, per
/// PlaybackQueue.withShuffleEnabled's own docs: the entity only
/// validates and stores a result supplied by the caller, because
/// deriving "where did the current song end up" from content is
/// ambiguous whenever the queue holds the same Song twice. This use
/// case shuffles a list of ORIGINAL INDICES rather than Song values,
/// so the current song's new position is tracked positionally even
/// with duplicates present.
final class ShuffleQueueUseCase
    implements UseCase<PlaybackQueue, ShuffleQueueParams> {
  ShuffleQueueUseCase(this._playbackRepository, {Random? random})
      : _random = random ?? Random();

  final PlaybackRepository _playbackRepository;

  /// Injectable so tests can supply a seeded [Random] for
  /// deterministic assertions instead of asserting on a genuinely
  /// random permutation.
  final Random _random;

  @override
  Future<Result<PlaybackQueue, Failure>> call(
    ShuffleQueueParams params,
  ) async {
    final queueResult = await _playbackRepository.getQueue(params.queueId);
    return queueResult.asyncAndThen((queue) async {
      final Result<PlaybackQueue, Failure> mutated;
      if (params.enable) {
        mutated = queue.shuffleEnabled ? Ok(queue) : _shuffle(queue);
      } else {
        mutated = Ok(queue.withShuffleDisabled());
      }
      return mutated.asyncAndThen((newQueue) async {
        final saveResult = await _playbackRepository.saveQueue(newQueue);
        return saveResult.asyncAndThen((_) async => Ok(newQueue));
      });
    });
  }

  Result<PlaybackQueue, Failure> _shuffle(PlaybackQueue queue) {
    final indices = List<int>.generate(queue.songs.length, (i) => i);
    // Fisher-Yates over indices, not over Song values.
    for (var i = indices.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }

    final shuffledSongs = [for (final i in indices) queue.songs[i]];
    final newCurrentIndex = indices.indexOf(queue.currentIndex);

    return queue.withShuffleEnabled(
      shuffled: shuffledSongs,
      newCurrentIndex: newCurrentIndex,
    );
  }
}