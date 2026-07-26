import 'dart:math';

import 'package:test/test.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/usecases/shuffle_queue_usecase.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/queue_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

import '../repositories/fakes/fake_playback_repository.dart';

Song _song(String id) {
  return Song.create(
    id: SongId(id),
    title: 'Title $id',
    trackArtistId: const ArtistId('artist-1'),
    duration: const Duration(minutes: 3),
    filePath: '/music/$id.mp3',
    format: AudioFormat.mp3,
    fileSizeBytes: 1000,
    dateAddedUtc: DateTime.utc(2026, 1, 1),
  ).valueOrNull!;
}

void main() {
  group('ShuffleQueueUseCase enable', () {
    test(
        'shuffles every song and correctly tracks the current song '
        'even when it appears twice', () async {
      final dup = _song('dup');
      final other = _song('other');
      // `dup` appears at index 0 AND index 2; currentIndex points at
      // the SECOND occurrence, so the shuffle must track that exact
      // position, not just "some dup".
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [dup, other, dup],
        currentIndex: 2,
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final repo = FakePlaybackRepository(initialQueues: [queue]);
      final useCase = ShuffleQueueUseCase(repo, random: Random(7));

      final result =
          await useCase.call((queueId: const QueueId('q1'), enable: true));

      final shuffled = result.valueOrNull!;
      expect(shuffled.shuffleEnabled, isTrue);
      expect(shuffled.songs.length, 3);
      expect(identical(shuffled.currentSong, dup), isTrue);
    });

    test('is a no-op when shuffle is already enabled', () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final repo = FakePlaybackRepository(initialQueues: [queue]);
      final useCase = ShuffleQueueUseCase(repo, random: Random(1));

      await useCase.call((queueId: const QueueId('q1'), enable: true));
      final second =
          await useCase.call((queueId: const QueueId('q1'), enable: true));

      final persisted = await repo.getQueue(const QueueId('q1'));
      expect(second.valueOrNull?.songs, persisted.valueOrNull?.songs);
    });

    test('persists the shuffled queue via the repository', () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b'), _song('c')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final repo = FakePlaybackRepository(initialQueues: [queue]);
      final useCase = ShuffleQueueUseCase(repo, random: Random(3));

      await useCase.call((queueId: const QueueId('q1'), enable: true));

      final persisted = await repo.getQueue(const QueueId('q1'));
      expect(persisted.valueOrNull?.shuffleEnabled, isTrue);
    });
  });

  group('ShuffleQueueUseCase disable', () {
    test('restores the exact pre-shuffle order and index', () async {
      final a = _song('a');
      final b = _song('b');
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [a, b],
        currentIndex: 1,
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final repo = FakePlaybackRepository(initialQueues: [queue]);
      final useCase = ShuffleQueueUseCase(repo, random: Random(5));

      await useCase.call((queueId: const QueueId('q1'), enable: true));
      final restored =
          await useCase.call((queueId: const QueueId('q1'), enable: false));

      expect(restored.valueOrNull?.songs, [a, b]);
      expect(restored.valueOrNull?.currentIndex, 1);
      expect(restored.valueOrNull?.shuffleEnabled, isFalse);
    });
  });
}