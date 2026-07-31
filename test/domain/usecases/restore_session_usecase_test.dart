import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/usecases/restore_session_usecase.dart';
import 'package:nexo/domain/usecases/use_case.dart';
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
  group('RestoreSessionUseCase', () {
    test('returns Ok(null) when there is no prior session', () async {
      final useCase = RestoreSessionUseCase(
        FakePlaybackRepository(),
        FakeAudioPlayerRepository(),
      );
      final result = await useCase.call(const NoParams());
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('loads the engine at the saved position without resuming', () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final playbackRepo = FakePlaybackRepository(initialQueues: [queue]);
      await playbackRepo.saveActiveSession(
        (
          activeQueueId: const QueueId('q1'),
          position: const Duration(seconds: 90),
        ),
      );
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = RestoreSessionUseCase(playbackRepo, audioRepo);

      final result = await useCase.call(const NoParams());

      expect(result.valueOrNull?.id, const QueueId('q1'));
      expect(audioRepo.loadedSong?.id.value, 'a');
      expect(audioRepo.loadedAt, const Duration(seconds: 90));
      expect(audioRepo.isResumed, isFalse);
    });

    test(
        'gracefully returns Ok(null) when the saved queue no longer '
        'exists', () async {
      final playbackRepo = FakePlaybackRepository();
      await playbackRepo.saveActiveSession(
        (
          activeQueueId: const QueueId('deleted-queue'),
          position: const Duration(seconds: 10),
        ),
      );
      final useCase =
          RestoreSessionUseCase(playbackRepo, FakeAudioPlayerRepository());

      final result = await useCase.call(const NoParams());

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });
}
