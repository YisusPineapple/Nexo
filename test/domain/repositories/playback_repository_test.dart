import 'package:test/test.dart';
import 'package:nexo/core/error/failures.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/playback_settings.dart';
import 'package:nexo/domain/entities/playback_speed.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/queue_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

import 'fakes/fake_playback_repository.dart';

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
  ).valueOrNull!;
}

void main() {
  group('PlaybackRepository contract (via FakePlaybackRepository)', () {
    test('getQueue returns Ok for an existing queue', () async {
      final repo = FakePlaybackRepository(initialQueues: [_queue('q1')]);
      final result = await repo.getQueue(const QueueId('q1'));
      expect(result.valueOrNull?.id, const QueueId('q1'));
    });

    test('getQueue returns NotFoundFailure for a missing queue', () async {
      final repo = FakePlaybackRepository();
      final result = await repo.getQueue(const QueueId('missing'));
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });

    test('saveQueue upserts a queue retrievable via getQueue', () async {
      final repo = FakePlaybackRepository();
      await repo.saveQueue(_queue('q1'));
      final result = await repo.getQueue(const QueueId('q1'));
      expect(result.isOk, isTrue);
    });

    test('deleteQueue removes a queue so a later getQueue fails', () async {
      final repo = FakePlaybackRepository(initialQueues: [_queue('q1')]);
      await repo.deleteQueue(const QueueId('q1'));
      final result = await repo.getQueue(const QueueId('q1'));
      expect(result.isErr, isTrue);
    });

    test('deleteQueue on a missing id returns NotFoundFailure', () async {
      final repo = FakePlaybackRepository();
      final result = await repo.deleteQueue(const QueueId('missing'));
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });

    test('getPlaybackSettings defaults to PlaybackSettings.defaults', () async {
      final repo = FakePlaybackRepository();
      final result = await repo.getPlaybackSettings();
      expect(result.valueOrNull, PlaybackSettings.defaults);
    });

    test('savePlaybackSettings persists the new settings', () async {
      final repo = FakePlaybackRepository();
      final newSettings = PlaybackSettings.defaults.copyWith(
        speed: PlaybackSpeed.create(multiplier: 1.5).valueOrNull,
      );
      await repo.savePlaybackSettings(newSettings);
      final result = await repo.getPlaybackSettings();
      expect(result.valueOrNull?.speed.multiplier, 1.5);
    });

    test('getLastSession is Ok(null) before any session is saved', () async {
      final repo = FakePlaybackRepository();
      final result = await repo.getLastSession();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test(
        'saveActiveSession makes the session retrievable via '
        'getLastSession', () async {
      final repo = FakePlaybackRepository();
      await repo.saveActiveSession(
        (
          activeQueueId: const QueueId('q1'),
          position: const Duration(seconds: 42),
        ),
      );
      final result = await repo.getLastSession();
      expect(result.valueOrNull?.activeQueueId, const QueueId('q1'));
      expect(result.valueOrNull?.position, const Duration(seconds: 42));
    });
  });
}
