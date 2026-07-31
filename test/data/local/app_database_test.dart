import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexo/data/local/app_database.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/crossfade_config.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/repeat_mode.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Songs table', () {
    test('round-trips a row, including the format and genre converters',
        () async {
      await db.into(db.songs).insert(SongsCompanion.insert(
            id: 's1',
            title: 'Test Song',
            trackArtistId: 'artist-1',
            durationMs: 180000,
            filePath: '/music/test.flac',
            format: AudioFormat.flac,
            fileSizeBytes: 30000000,
            genreNames: const ['Ambient', 'Electronic'],
            dateAddedUtcMs: 0,
          ));

      final rows = await db.select(db.songs).get();

      expect(rows, hasLength(1));
      expect(rows.first.format, AudioFormat.flac);
      expect(rows.first.genreNames, ['Ambient', 'Electronic']);
      expect(rows.first.isMissing, isFalse); // withDefault(false)
    });
  });

  group('PlaybackQueues + QueueSongs', () {
    test('round-trips repeatMode and a non-trivial QueueSource', () async {
      await db.into(db.playbackQueues).insert(PlaybackQueuesCompanion.insert(
            id: 'q1',
            currentIndex: 0,
            repeatMode: RepeatMode.all,
            source: const ArtistQueueSource(
              artistId: ArtistId('artist-1'),
              artistName: 'Boards',
            ),
          ));

      final queue = await (db.select(db.playbackQueues)
            ..where((t) => t.id.equals('q1')))
          .getSingle();

      expect(queue.repeatMode, RepeatMode.all);
      expect(
        queue.source,
        const ArtistQueueSource(
          artistId: ArtistId('artist-1'),
          artistName: 'Boards',
        ),
      );
    });

    test('preserves duplicate songIds at distinct positions', () async {
      await db.into(db.playbackQueues).insert(PlaybackQueuesCompanion.insert(
            id: 'q1',
            currentIndex: 2,
            repeatMode: RepeatMode.off,
            source: const ManualQueueSource(),
          ));

      // 'dup' appears at position 0 AND position 2 — the exact
      // scenario Domain's positional tracking is designed for.
      await db.batch((batch) {
        batch.insertAll(db.queueSongs, [
          QueueSongsCompanion.insert(
            queueId: 'q1',
            listKind: 'current',
            position: 0,
            songId: 'dup',
          ),
          QueueSongsCompanion.insert(
            queueId: 'q1',
            listKind: 'current',
            position: 1,
            songId: 'other',
          ),
          QueueSongsCompanion.insert(
            queueId: 'q1',
            listKind: 'current',
            position: 2,
            songId: 'dup',
          ),
        ]);
      });

      // Two chained .where() calls instead of `&` — always ANDs
      // together in drift, and sidesteps relying on an operator I
      // can't verify is available in this exact version.
      final ordered = await (db.select(db.queueSongs)
            ..where((t) => t.queueId.equals('q1'))
            ..where((t) => t.listKind.equals('current'))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

      expect(ordered.map((r) => r.songId), ['dup', 'other', 'dup']);
    });
  });

  group('PlaybackSettingsTable', () {
    test('round-trips crossfade mode and speed', () async {
      await db.into(db.playbackSettingsTable).insertOnConflictUpdate(
            PlaybackSettingsTableCompanion.insert(
              crossfadeMode: CrossfadeMode.intelligent,
              crossfadeDurationMs: 6000,
              speedHundredths: 125,
              pitchCorrectionEnabled: true,
            ),
          );

      final settings = await db.select(db.playbackSettingsTable).getSingle();

      expect(settings.crossfadeMode, CrossfadeMode.intelligent);
      expect(settings.speedHundredths, 125);
    });
  });

  group('ActiveSessionTable', () {
    test('an empty table means "no session"', () async {
      final rows = await db.select(db.activeSessionTable).get();
      expect(rows, isEmpty);
    });

    test('round-trips a saved session', () async {
      await db.into(db.activeSessionTable).insertOnConflictUpdate(
            ActiveSessionTableCompanion.insert(
              activeQueueId: 'q1',
              positionMs: 90000,
            ),
          );

      final session = await db.select(db.activeSessionTable).getSingle();
      expect(session.activeQueueId, 'q1');
      expect(session.positionMs, 90000);
    });
  });
}
