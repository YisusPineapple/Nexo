import 'package:test/test.dart';
import 'package:nexo/core/error/failures.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/usecases/reorder_queue_usecase.dart';
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
  group('ReorderQueueUseCase', () {
    test('moves a song and persists the updated queue', () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b'), _song('c')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final repo = FakePlaybackRepository(initialQueues: [queue]);
      final useCase = ReorderQueueUseCase(repo);

      final result = await useCase.call(
        (queueId: const QueueId('q1'), oldIndex: 0, newIndex: 2),
      );

      expect(result.valueOrNull?.songs.map((s) => s.id.value), ['b', 'c', 'a']);

      final persisted = await repo.getQueue(const QueueId('q1'));
      expect(
        persisted.valueOrNull?.songs.map((s) => s.id.value),
        ['b', 'c', 'a'],
      );
    });

    test('propagates a ValidationFailure for an out-of-bounds index',
        () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final repo = FakePlaybackRepository(initialQueues: [queue]);
      final useCase = ReorderQueueUseCase(repo);

      final result = await useCase.call(
        (queueId: const QueueId('q1'), oldIndex: 5, newIndex: 0),
      );

      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<ValidationFailure>(),
      );
    });

    test('propagates NotFoundFailure for an unknown queue', () async {
      final useCase = ReorderQueueUseCase(FakePlaybackRepository());
      final result = await useCase.call(
        (queueId: const QueueId('missing'), oldIndex: 0, newIndex: 1),
      );
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });
  });
}