import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:nexo/data/local/app_database.dart';

/// Sprint 9 / T2 schema 16 migration test.
///
/// Schema 16 adds functional sort indexes (LOWER(title), LOWER(track_artist_id),
/// LOWER(album_id)) plus plain-column indexes for year, duration_ms, and
/// date_added_utc_ms, and runs ANALYZE. No column or table shape changes —
/// the migration is purely DDL addition. These indexes are what makes
/// LIMIT/OFFSET pagination viable (see Sprint9_P0_T2.md §5.1 and §5.3: 38.12
/// ms → 1.13 ms median OFFSET 10000 on 15,000 rows).
///
/// The migration must be idempotent: it is invoked from both `onCreate`
/// (fresh installs at v16) and `onUpgrade(from < 16)` (upgrades from any
/// version 15 or earlier). This file verifies the two paths reach the same
/// end state and that a downgraded v15 DB is upgraded correctly.

const _expectedIndexes = [
  'idx_songs_title_lower',
  'idx_songs_artist_lower',
  'idx_songs_album_lower',
  'idx_songs_year',
  'idx_songs_duration',
  'idx_songs_date_added',
];

Future<Set<String>> _readSortIndexNames(AppDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'index' AND name IN "
        "('idx_songs_title_lower', 'idx_songs_artist_lower', "
        "'idx_songs_album_lower', 'idx_songs_year', "
        "'idx_songs_duration', 'idx_songs_date_added')",
      )
      .get();
  return rows.map((r) => r.data['name'] as String).toSet();
}

Future<int> _readSchemaVersion(AppDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.data['user_version'] as int;
}

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexo_migration_v16_test_');
    dbFile = File(p.join(tempDir.path, 'nexo.sqlite'));
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('Schema 16 — fresh install (onCreate path)', () {
    test('creates every sort index on a new DB', () async {
      final db = AppDatabase(openConnection(dbFile));
      try {
        // Lazy-open: onCreate runs on the first query.
        await db.customSelect('SELECT 1').get();

        final version = await _readSchemaVersion(db);
        expect(version, 16);

        final indexes = await _readSortIndexNames(db);
        expect(indexes, containsAll(_expectedIndexes),
            reason: 'onCreate must call _createSortIndexes — without this, '
                'a fresh install at v16 would be missing the indexes that '
                'make pagination viable, and §5.3 would not apply.');
      } finally {
        await db.close();
      }
    });

    test('the sort indexes are actually used by the planner (EXPLAIN)',
        () async {
      final db = AppDatabase(openConnection(dbFile));
      try {
        await db.customSelect('SELECT 1').get();

        // Seed a handful of rows so the planner has something to consider.
        for (var i = 0; i < 20; i++) {
          await db.customStatement(
            'INSERT INTO songs ('
            '  title, track_artist_id, album_id, duration_ms, file_path, '
            '  format, file_size_bytes, genre_names, date_added_utc_ms'
            ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              'Title ${i.toString().padLeft(3, '0')}',
              'Artist $i',
              'Album $i',
              1000 + i,
              '/music/s${i.toString().padLeft(3, '0')}.mp3',
              'mp3',
              100,
              '',
              0,
            ],
          );
        }
        await db.customStatement('ANALYZE;');

        final plan = await db
            .customSelect(
              'EXPLAIN QUERY PLAN '
              'SELECT * FROM songs ORDER BY LOWER(title) ASC LIMIT 50 OFFSET 10',
            )
            .get();
        final detail =
            plan.map((r) => r.data['detail'] as String? ?? '').join(' | ');
        expect(detail.toLowerCase(), contains('idx_songs_title_lower'),
            reason: 'The LOWER(title) ORDER BY must hit the functional '
                'index; otherwise §5.1 numbers apply, not §5.3. Got: $detail');
      } finally {
        await db.close();
      }
    });
  });

  group('Schema 16 — migration from v15 (onUpgrade path)', () {
    test('v15 → v16 recreates the sort indexes when they were missing',
        () async {
      // Step 1: open fresh at v16, then simulate a v15 DB by dropping the
      // new indexes and downgrading user_version. This models an install
      // that predates Sprint 9 / T2 and never had these indexes.
      {
        final db = AppDatabase(openConnection(dbFile));
        try {
          await db.customSelect('SELECT 1').get();
          expect(await _readSchemaVersion(db), 16);

          await db
              .customStatement('DROP INDEX IF EXISTS idx_songs_title_lower;');
          await db
              .customStatement('DROP INDEX IF EXISTS idx_songs_artist_lower;');
          await db
              .customStatement('DROP INDEX IF EXISTS idx_songs_album_lower;');
          await db.customStatement('DROP INDEX IF EXISTS idx_songs_year;');
          await db.customStatement('DROP INDEX IF EXISTS idx_songs_duration;');
          await db
              .customStatement('DROP INDEX IF EXISTS idx_songs_date_added;');

          final afterDrop = await _readSortIndexNames(db);
          expect(afterDrop, isEmpty,
              reason: 'All six indexes must be droppable for the test '
                  'to model a genuine pre-v16 install.');

          await db.customStatement('PRAGMA user_version = 15;');
          expect(await _readSchemaVersion(db), 15);
        } finally {
          await db.close();
        }
      }

      // Step 2: reopen. onUpgrade(from: 15, to: 16) must fire and recreate
      // the indexes.
      final db = AppDatabase(openConnection(dbFile));
      try {
        await db.customSelect('SELECT 1').get();

        final version = await _readSchemaVersion(db);
        expect(version, 16);

        final indexes = await _readSortIndexNames(db);
        expect(indexes, containsAll(_expectedIndexes),
            reason: 'onUpgrade(from < 16) must call _createSortIndexes.');
      } finally {
        await db.close();
      }
    });

    test('re-running the migration is idempotent (IF NOT EXISTS honored)',
        () async {
      // Open, then downgrade and reopen twice — the CREATE INDEX IF NOT
      // EXISTS clauses must be no-ops on the second pass.
      {
        final db = AppDatabase(openConnection(dbFile));
        try {
          await db.customSelect('SELECT 1').get();
        } finally {
          await db.close();
        }
      }

      for (var pass = 0; pass < 2; pass++) {
        final db = AppDatabase(openConnection(dbFile));
        try {
          await db.customSelect('SELECT 1').get();
          // Downgrade to force the migration again on next open.
          await db.customStatement('PRAGMA user_version = 15;');
        } finally {
          await db.close();
        }
      }

      final db = AppDatabase(openConnection(dbFile));
      try {
        await db.customSelect('SELECT 1').get();
        expect(await _readSchemaVersion(db), 16);

        final indexes = await _readSortIndexNames(db);
        expect(indexes, containsAll(_expectedIndexes),
            reason: 'Repeated migrations must not fail or lose indexes.');
      } finally {
        await db.close();
      }
    });
  });

  group('Schema 16 — schema-15 migration test file is not affected', () {
    test('the v14 → v15 test file remains valid (spot-check the seed shape)',
        () async {
      // Cheap guard: verify that opening a fresh v16 DB leaves a songs table
      // that the v14 → v15 test's post-conditions would still pass against
      // (stable integer ids, UNIQUE file_path). This is not a re-run of that
      // test — that file owns its own coverage — it just confirms the v16
      // migration did not regress the shape v15 landed.
      final db = AppDatabase(openConnection(dbFile));
      try {
        await db.customSelect('SELECT 1').get();

        await db.customStatement(
          'INSERT INTO songs ('
          '  title, track_artist_id, album_id, duration_ms, file_path, '
          '  format, file_size_bytes, genre_names, date_added_utc_ms'
          ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'T',
            'A',
            'Al',
            1000,
            '/music/t.mp3',
            'mp3',
            100,
            '',
            0,
          ],
        );

        // file_path UNIQUE still enforced.
        expect(
          () => db.customStatement(
            'INSERT INTO songs ('
            '  title, track_artist_id, album_id, duration_ms, file_path, '
            '  format, file_size_bytes, genre_names, date_added_utc_ms'
            ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              'U',
              'B',
              'Bl',
              1000,
              '/music/t.mp3',
              'mp3',
              100,
              '',
              0,
            ],
          ),
          throwsA(anything),
        );
      } finally {
        await db.close();
      }
    });
  });
}
