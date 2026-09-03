import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/core/error/failures.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/usecases/multi_queue_usecases.dart';
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

PlaybackQueue _queue(String id) {
  return PlaybackQueue.create(
    id: QueueId(id),
    songs: [_song('a')],
    source: const ManualQueueSource(),
    position: const Duration(seconds: 10),
  ).valueOrNull!;
}

void main() {
  group('OpenQueueUseCase', () {
    test('saves queue and syncs audio when under limit', () async {
      final playbackRepo = FakePlaybackRepository();
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = OpenQueueUseCase(playbackRepo, audioRepo);

      final result = await useCase.call((queue: _queue('q1'), asNewTab: true));

      expect(result.isOk, isTrue);
      final saved = await playbackRepo.getQueue(const QueueId('q1'));
      expect(saved.isOk, isTrue);
      expect(audioRepo.syncedQueue?.length, 1);
    });

    test('rejects new tab if limit is reached', () async {
      final queues = List.generate(5, (i) => _queue('q$i'));
      final playbackRepo = FakePlaybackRepository(initialQueues: queues);
      final useCase =
          OpenQueueUseCase(playbackRepo, FakeAudioPlayerRepository());

      final result = await useCase.call((queue: _queue('q6'), asNewTab: true));

      expect(result.isErr, isTrue);
      expect(result.when(ok: (_) => null, err: (e) => e),
          isA<ValidationFailure>());
    });

    test(
        'a normal (non-new-tab) open overwrites the active queue slot '
        'instead of creating a new one', () async {
      final playbackRepo =
          FakePlaybackRepository(initialQueues: [_queue('album_42')]);
      await playbackRepo.saveActiveSession(
        (activeQueueId: const QueueId('album_42'), position: Duration.zero),
      );
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = OpenQueueUseCase(playbackRepo, audioRepo);

      final result =
          await useCase.call((queue: _queue('genre_rock'), asNewTab: false));

      expect(result.isOk, isTrue);

      final overwritten =
          await playbackRepo.getQueue(const QueueId('album_42'));
      expect(overwritten.isOk, isTrue);

      final all = await playbackRepo.getAllQueues();
      expect(all.valueOrNull?.length, 1);
    });

    test('with no prior session, a normal open uses the given queue id',
        () async {
      final playbackRepo = FakePlaybackRepository();
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = OpenQueueUseCase(playbackRepo, audioRepo);

      final result =
          await useCase.call((queue: _queue('library_songs'), asNewTab: false));

      expect(result.isOk, isTrue);
      final saved = await playbackRepo.getQueue(const QueueId('library_songs'));
      expect(saved.isOk, isTrue);
    });
  });

  group('SwitchQueueUseCase', () {
    test('loads target queue paused at saved position', () async {
      final queue = _queue('q1');
      final playbackRepo = FakePlaybackRepository(initialQueues: [queue]);
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = SwitchQueueUseCase(playbackRepo, audioRepo);

      final result = await useCase.call(const QueueId('q1'));

      expect(result.isOk, isTrue);

      expect(audioRepo.syncedQueue?.first.id.value, 'a');
      expect(audioRepo.seekedTo, const Duration(seconds: 10));
      expect(audioRepo.isPaused, isTrue);

      final session = await playbackRepo.getLastSession();
      expect(session.valueOrNull?.activeQueueId, const QueueId('q1'));
    });
  });

  group('CloseQueueUseCase', () {
    test('deletes queue and switches to another if it was active', () async {
      final q1 = _queue('q1');
      final q2 = _queue('q2');
      final playbackRepo = FakePlaybackRepository(initialQueues: [q1, q2]);
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = CloseQueueUseCase(playbackRepo, audioRepo);

      final result = await useCase.call((
        queueIdToClose: const QueueId('q2'),
        activeQueueId: const QueueId('q2'),
      ));

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.id, const QueueId('q1'));

      final deleted = await playbackRepo.getQueue(const QueueId('q2'));
      expect(deleted.isErr, isTrue);
    });

    test('clears session and stops player if last queue is closed', () async {
      final q1 = _queue('q1');
      final playbackRepo = FakePlaybackRepository(initialQueues: [q1]);
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = CloseQueueUseCase(playbackRepo, audioRepo);

      final result = await useCase.call((
        queueIdToClose: const QueueId('q1'),
        activeQueueId: const QueueId('q1'),
      ));

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
      expect(audioRepo.loadedSong, isNull);

      final session = await playbackRepo.getLastSession();
      expect(session.valueOrNull, isNull);
    });
  });
}
