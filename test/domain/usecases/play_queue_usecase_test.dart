import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/core/error/failures.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/usecases/play_queue_usecase.dart';
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

PlaybackQueue _queue(String id, {int currentIndex = 0}) {
  return PlaybackQueue.create(
    id: QueueId(id),
    songs: [_song('a'), _song('b')],
    currentIndex: currentIndex,
    source: const ManualQueueSource(),
  ).valueOrNull!;
}

void main() {
  group('PlayQueueUseCase.play', () {
    test('loads and resumes the current song', () async {
      final playbackRepo =
          FakePlaybackRepository(initialQueues: [_queue('q1')]);
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = PlayQueueUseCase(playbackRepo, audioRepo);

      final result = await useCase.play(const QueueId('q1'));

      expect(result.isOk, isTrue);
      expect(audioRepo.loadedSong?.id.value, 'a');
      expect(audioRepo.isResumed, isTrue);
    });

    test('fails with ValidationFailure when the queue has no current song',
        () async {
      final emptyQueue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: const [],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final playbackRepo = FakePlaybackRepository(initialQueues: [emptyQueue]);
      final useCase =
          PlayQueueUseCase(playbackRepo, FakeAudioPlayerRepository());

      final result = await useCase.play(const QueueId('q1'));

      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<ValidationFailure>(),
      );
    });

    test('propagates NotFoundFailure for an unknown queue', () async {
      final useCase = PlayQueueUseCase(
        FakePlaybackRepository(),
        FakeAudioPlayerRepository(),
      );
      final result = await useCase.play(const QueueId('missing'));
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });
  });

  group('PlayQueueUseCase.skipNext', () {
    test('advances the queue and loads the new current song', () async {
      final playbackRepo =
          FakePlaybackRepository(initialQueues: [_queue('q1')]);
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = PlayQueueUseCase(playbackRepo, audioRepo);

      final result = await useCase.skipNext(const QueueId('q1'));

      expect(result.valueOrNull?.currentIndex, 1);
      expect(audioRepo.loadedSong?.id.value, 'b');
      expect(audioRepo.isResumed, isTrue);
    });

    test('reaching the natural end stops without loading a song', () async {
      final playbackRepo = FakePlaybackRepository(
        initialQueues: [_queue('q1', currentIndex: 1)], // last of 2 songs
      );
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = PlayQueueUseCase(playbackRepo, audioRepo);

      final result = await useCase.skipNext(const QueueId('q1'));

      expect(result.valueOrNull?.currentIndex, -1);
      expect(audioRepo.loadedSong, isNull);
    });
  });

  group('PlayQueueUseCase.pause / seekTo', () {
    test('pause delegates to the audio engine', () async {
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = PlayQueueUseCase(FakePlaybackRepository(), audioRepo);
      await useCase.pause();
      expect(audioRepo.isPaused, isTrue);
    });

    test('seekTo delegates the exact position to the audio engine', () async {
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = PlayQueueUseCase(FakePlaybackRepository(), audioRepo);
      await useCase.seekTo(const Duration(seconds: 30));
      expect(audioRepo.seekedTo, const Duration(seconds: 30));
    });
  });
}
