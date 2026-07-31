// test/data/repositories/playback_repository_impl_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexo/core/error/failures.dart';
import 'package:nexo/data/local/app_database.dart';
import 'package:nexo/data/local/mappers/song_mapper.dart';
import 'package:nexo/data/repositories/playback_repository_impl.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/crossfade_config.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/playback_settings.dart';
import 'package:nexo/domain/entities/playback_speed.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/queue_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

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
  late AppDatabase db;
  late PlaybackRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PlaybackRepositoryImpl(db);
    for (final id in ['a', 'b', 'c']) {
      await db.into(db.songs).insert(const SongMapper().toCompanion(_song(id)));
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('Queue persistence', () {
    test('saveQueue then getQueue round-trips an unshuffled queue', () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b'), _song('c')],
        currentIndex: 1,
        source: const ManualQueueSource(),
      ).valueOrNull!;

      await repo.saveQueue(queue);
      final result = await repo.getQueue(const QueueId('q1'));

      expect(result.isOk, isTrue);
      expect(
        result.valueOrNull?.songs.map((s) => s.id.value),
        ['a', 'b', 'c'],
      );
      expect(result.valueOrNull?.currentIndex, 1);
    });

    test(
        'preserves a duplicated song at distinct positions through a '
        'full round-trip', () async {
      final dup = _song('a');
      final other = _song('b');
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [dup, other, dup],
        currentIndex: 2,
        source: const ManualQueueSource(),
      ).valueOrNull!;

      await repo.saveQueue(queue);
      final result = await repo.getQueue(const QueueId('q1'));

      expect(
        result.valueOrNull?.songs.map((s) => s.id.value),
        ['a', 'b', 'a'],
      );
      expect(result.valueOrNull?.currentIndex, 2);
    });

    test(
        'round-trips a shuffled queue including its exact pre-shuffle '
        'snapshot', () async {
      final a = _song('a');
      final b = _song('b');
      final c = _song('c');
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [a, b, c],
        currentIndex: 1,
        source: const ManualQueueSource(),
      ).valueOrNull!.withShuffleEnabled(
          shuffled: [c, a, b], newCurrentIndex: 1).valueOrNull!;

      await repo.saveQueue(queue);
      final restored = (await repo.getQueue(const QueueId('q1'))).valueOrNull!;

      expect(restored.songs.map((s) => s.id.value), ['c', 'a', 'b']);
      expect(restored.shuffleEnabled, isTrue);

      final unshuffled = restored.withShuffleDisabled();
      expect(unshuffled.songs.map((s) => s.id.value), ['a', 'b', 'c']);
      expect(unshuffled.currentIndex, 1);
    });

    test('getQueue returns NotFoundFailure for a missing id', () async {
      final result = await repo.getQueue(const QueueId('missing'));
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });

    test('deleteQueue removes a queue so a later getQueue fails', () async {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      await repo.saveQueue(queue);

      expect((await repo.deleteQueue(const QueueId('q1'))).isOk, isTrue);
      expect((await repo.getQueue(const QueueId('q1'))).isErr, isTrue);
    });

    test('deleteQueue on a missing id returns NotFoundFailure', () async {
      final result = await repo.deleteQueue(const QueueId('missing'));
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });
  });

  group('PlaybackSettings persistence', () {
    test('getPlaybackSettings defaults when nothing was ever saved', () async {
      final result = await repo.getPlaybackSettings();
      expect(result.valueOrNull, PlaybackSettings.defaults);
    });

    test('savePlaybackSettings then getPlaybackSettings round-trips', () async {
      final settings = PlaybackSettings(
        crossfade: CrossfadeConfig.create(
          mode: CrossfadeMode.fixed,
          duration: const Duration(seconds: 6),
        ).valueOrNull!,
        speed: PlaybackSpeed.create(multiplier: 1.25).valueOrNull!,
      );

      await repo.savePlaybackSettings(settings);
      final result = await repo.getPlaybackSettings();

      expect(result.valueOrNull?.speed.multiplier, 1.25);
      expect(
        result.valueOrNull?.crossfade.duration,
        const Duration(seconds: 6),
      );
    });
  });

  group('Active session persistence', () {
    test('getLastSession is Ok(null) before anything is saved', () async {
      final result = await repo.getLastSession();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('saveActiveSession makes the session retrievable', () async {
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
