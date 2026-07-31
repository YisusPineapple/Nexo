import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/core/error/failures.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/usecases/handle_playback_error_usecase.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/queue_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

import '../repositories/fakes/fake_audio_player_repository.dart';
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
  group('HandlePlaybackErrorUseCase', () {
    test('decodeError auto-skips to the next song and resumes', () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final playbackRepo = FakePlaybackRepository(initialQueues: [queue]);
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = HandlePlaybackErrorUseCase(playbackRepo, audioRepo);

      final result = await useCase.call((
        queueId: const QueueId('q1'),
        error: const PlaybackFailure(
          'bad file',
          reason: PlaybackFailureReason.decodeError,
        ),
      ));

      expect(result.valueOrNull?.currentIndex, 1);
      expect(audioRepo.loadedSong?.id.value, 'b');
      expect(audioRepo.isResumed, isTrue);
    });

    test('decodeError at the last song stops without loading anything',
        () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final playbackRepo = FakePlaybackRepository(initialQueues: [queue]);
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = HandlePlaybackErrorUseCase(playbackRepo, audioRepo);

      final result = await useCase.call((
        queueId: const QueueId('q1'),
        error: const PlaybackFailure(
          'bad file',
          reason: PlaybackFailureReason.decodeError,
        ),
      ));

      expect(result.valueOrNull?.currentIndex, -1);
      expect(audioRepo.loadedSong, isNull);
    });

    test('engineError is returned as-is, without touching the queue', () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final playbackRepo = FakePlaybackRepository(initialQueues: [queue]);
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = HandlePlaybackErrorUseCase(playbackRepo, audioRepo);
      const error = PlaybackFailure(
        'device disappeared',
        reason: PlaybackFailureReason.engineError,
      );

      final result =
          await useCase.call((queueId: const QueueId('q1'), error: error));

      expect(result.when(ok: (_) => null, err: (e) => e), error);
      expect(audioRepo.loadedSong, isNull);

      final unchanged = await playbackRepo.getQueue(const QueueId('q1'));
      expect(unchanged.valueOrNull?.currentIndex, 0);
    });
  });
}
