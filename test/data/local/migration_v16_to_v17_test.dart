import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:nexo/data/local/app_database.dart';

/// Sprint 9 / T3 schema 17 migration test.
///
/// Schema 17 invalidates every cached cover art path. The pre-17 cover
/// cache keyed filenames on `String.hashCode`, which is not stable across
/// isolates or app restarts (see ARCHITECTURE.md §2.5). After the fix
/// (`computeCoverId` = SHA-256 over raw cover bytes), the migration
/// resets every existing `cover_art_path` to NULL so the background
/// extractor re-populates the table with content-addressed paths on the
/// next cycle.
///
/// This file verifies ONLY the SQL state of the `songs` table. It does
/// NOT touch the filesystem — the cache-directory purge is a separate,
/// post-commit, best-effort step in `main.dart`, and would require a
/// whole different test harness (temp directory + marker file + failure
/// injection). Keeping the two concerns apart is deliberate (see the
/// ticket's Correction 5).
///
/// Schema 17 adds no columns, no tables, no indexes — the entire change
/// is a single UPDATE. A "v16 database" is therefore schema-identical to
/// a fresh v17 database; the tests below simulate one by manually
/// downgrading `user_version` after a fresh open.

Future<int> _readSchemaVersion(AppDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.data['user_version'] as int;
}

/// Inserts a song row with explicit cover_art_path and has_no_cover
/// values. Written as raw SQL because the song_id_map scheme and the
/// `SongsCompanion` type do not expose both columns in a single,
/// self-contained call that stays readable here.
Future<void> _insertSong(
  AppDatabase db, {
  required String filePath,
  required String? coverArtPath,
  required bool hasNoCover,
}) async {
  await db.customStatement(
    'INSERT INTO songs ('
    '  title, track_artist_id, album_id, duration_ms, file_path, '
    '  format, file_size_bytes, genre_names, date_added_utc_ms, '
    '  cover_art_path, has_no_cover'
    ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'T',
      'artist',
      'album',
      1000,
      filePath,
      'mp3',
      100,
      '',
      0,
      coverArtPath,
      hasNoCover ? 1 : 0,
    ],
  );
}

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexo_migration_v17_test_');
    dbFile = File(p.join(tempDir.path, 'nexo.sqlite'));
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('Schema 17 — cover art cache invalidation', () {
    test(
        'nulls cover_art_path and resets has_no_cover for every row that '
        'had a non-null cover path', () async {
      // Step 1: seed on a fresh v17 DB, then downgrade to simulate v16.
      {
        final db = AppDatabase(openConnection(dbFile));
        try {
          await db.customSelect('SELECT 1').get();
          expect(await _readSchemaVersion(db), 17);

          await _insertSong(
            db,
            filePath: '/music/a.mp3',
            coverArtPath: '/covers/deadbeef.jpg',
            hasNoCover: false,
          );
          await _insertSong(
            db,
            filePath: '/music/b.mp3',
            coverArtPath: '/covers/cafebabe.jpg',
            hasNoCover: false,
          );
          await _insertSong(
            db,
            filePath: '/music/c.mp3',
            coverArtPath: null,
            hasNoCover: false,
          );

          await db.customStatement('PRAGMA user_version = 16;');
          expect(await _readSchemaVersion(db), 16);
        } finally {
          await db.close();
        }
      }

      // Step 2: reopen → onUpgrade(from: 16, to: 17) runs.
      final db = AppDatabase(openConnection(dbFile));
      try {
        await db.customSelect('SELECT 1').get();
        expect(await _readSchemaVersion(db), 17);

        final rows = await db
            .customSelect(
              'SELECT file_path, cover_art_path, has_no_cover FROM songs '
              'ORDER BY file_path',
            )
            .get();

        expect(rows.length, 3);
        for (final row in rows) {
          expect(
            row.data['cover_art_path'],
            isNull,
            reason: 'Schema 17 must NULL every cover_art_path — the '
                'legacy String.hashCode naming made every cached path '
                'untrustworthy. See ARCHITECTURE.md §2.5.',
          );
          expect(
            row.data['has_no_cover'],
            0,
            reason: 'has_no_cover must reset to 0 so the extractor '
                're-attempts the cover on the next cycle.',
          );
        }
      } finally {
        await db.close();
      }
    });

    test(
        'a row with has_no_cover = 1 and cover_art_path = NULL is left '
        'semantically intact (WHERE excludes it)', () async {
      {
        final db = AppDatabase(openConnection(dbFile));
        try {
          await db.customSelect('SELECT 1').get();

          await _insertSong(
            db,
            filePath: '/music/nc.mp3',
            coverArtPath: null,
            hasNoCover: true,
          );
          await _insertSong(
            db,
            filePath: '/music/wc.mp3',
            coverArtPath: '/covers/stale.jpg',
            hasNoCover: false,
          );

          await db.customStatement('PRAGMA user_version = 16;');
        } finally {
          await db.close();
        }
      }

      final db = AppDatabase(openConnection(dbFile));
      try {
        await db.customSelect('SELECT 1').get();
        expect(await _readSchemaVersion(db), 17);

        final noCover = await db
            .customSelect(
              "SELECT cover_art_path, has_no_cover FROM songs "
              "WHERE file_path = '/music/nc.mp3'",
            )
            .getSingle();
        expect(noCover.data['cover_art_path'], isNull);
        expect(
          noCover.data['has_no_cover'],
          1,
          reason: 'A song already known to have no cover must not be '
              're-queued for cover extraction — the migration must not '
              'reset has_no_cover on a row the WHERE clause excludes.',
        );

        final withCover = await db
            .customSelect(
              "SELECT cover_art_path, has_no_cover FROM songs "
              "WHERE file_path = '/music/wc.mp3'",
            )
            .getSingle();
        expect(withCover.data['cover_art_path'], isNull);
        expect(withCover.data['has_no_cover'], 0);
      } finally {
        await db.close();
      }
    });

    test('running the migration twice is idempotent', () async {
      {
        final db = AppDatabase(openConnection(dbFile));
        try {
          await db.customSelect('SELECT 1').get();
          await _insertSong(
            db,
            filePath: '/music/x.mp3',
            coverArtPath: '/covers/x.jpg',
            hasNoCover: false,
          );
          await db.customStatement('PRAGMA user_version = 16;');
        } finally {
          await db.close();
        }
      }

      // First migration.
      {
        final db = AppDatabase(openConnection(dbFile));
        try {
          await db.customSelect('SELECT 1').get();
          expect(await _readSchemaVersion(db), 17);
        } finally {
          await db.close();
        }
      }

      // Force a second pass by downgrading again and reopening.
      {
        final db = AppDatabase(openConnection(dbFile));
        try {
          await db.customSelect('SELECT 1').get();
          await db.customStatement('PRAGMA user_version = 16;');
        } finally {
          await db.close();
        }
      }

      final db = AppDatabase(openConnection(dbFile));
      try {
        await db.customSelect('SELECT 1').get();
        expect(await _readSchemaVersion(db), 17);

        final row = await db
            .customSelect(
              "SELECT cover_art_path, has_no_cover FROM songs "
              "WHERE file_path = '/music/x.mp3'",
            )
            .getSingle();
        expect(row.data['cover_art_path'], isNull);
        expect(row.data['has_no_cover'], 0);
      } finally {
        await db.close();
      }
    });
  });
}
