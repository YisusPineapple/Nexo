import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:nexo/data/local/app_database.dart';

// --- v14 DDL: the schema BEFORE the T1 migration ---
//
// Hand-written because Drift no longer generates it — the table
// definitions in songs_table.dart etc. now describe the v15 shape.
// This is a valid v14-equivalent schema, which is all the migration
// needs in order to read from it. The exact DDL Drift used to emit is
// irrelevant here; what matters is that:
//   - songs.id is TEXT (no INTEGER PRIMARY KEY),
//   - songs.file_path has no UNIQUE constraint,
//   - the FK tables carry TEXT song_id columns,
//   - songs_fts exists with the same shape and triggers.
const _v14Ddl = '''
CREATE TABLE songs (
  id TEXT NOT NULL,
  title TEXT NOT NULL,
  track_artist_id TEXT NOT NULL,
  album_artist_id TEXT,
  album_id TEXT,
  track_number INTEGER,
  disc_number INTEGER,
  duration_ms INTEGER NOT NULL,
  file_path TEXT NOT NULL,
  format TEXT NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  genre_names TEXT NOT NULL,
  year INTEGER,
  cover_art_path TEXT,
  leading_silence_ms INTEGER NOT NULL DEFAULT 0,
  trailing_silence_ms INTEGER NOT NULL DEFAULT 0,
  replay_gain_track_db REAL,
  replay_gain_album_db REAL,
  date_added_utc_ms INTEGER NOT NULL,
  is_missing INTEGER NOT NULL DEFAULT 0 CHECK (is_missing IN (0, 1)),
  lyric_offset_ms INTEGER NOT NULL DEFAULT 0,
  has_no_cover INTEGER NOT NULL DEFAULT 0 CHECK (has_no_cover IN (0, 1)),
  section_key TEXT NOT NULL DEFAULT '#',
  PRIMARY KEY (id)
);

CREATE TABLE playlists (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  date_created_utc_ms INTEGER NOT NULL
);

CREATE TABLE playback_queues (
  id TEXT NOT NULL PRIMARY KEY,
  current_index INTEGER NOT NULL,
  repeat_mode TEXT NOT NULL,
  source TEXT NOT NULL,
  shuffle_enabled INTEGER NOT NULL DEFAULT 0 CHECK (shuffle_enabled IN (0, 1)),
  pre_shuffle_current_index INTEGER,
  position_ms INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE playlist_songs (
  playlist_id TEXT NOT NULL REFERENCES playlists (id),
  position INTEGER NOT NULL,
  song_id TEXT NOT NULL REFERENCES songs (id),
  PRIMARY KEY (playlist_id, position)
);

CREATE TABLE queue_songs (
  queue_id TEXT NOT NULL REFERENCES playback_queues (id),
  list_kind TEXT NOT NULL,
  position INTEGER NOT NULL,
  song_id TEXT NOT NULL REFERENCES songs (id),
  PRIMARY KEY (queue_id, list_kind, position)
);

CREATE TABLE playback_history (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  song_id TEXT NOT NULL REFERENCES songs (id),
  timestamp_utc_ms INTEGER NOT NULL
);

CREATE TABLE item_interactions (
  item_id TEXT NOT NULL,
  item_type TEXT NOT NULL,
  interaction INTEGER NOT NULL,
  timestamp_utc_ms INTEGER NOT NULL,
  PRIMARY KEY (item_id, item_type)
);

CREATE VIRTUAL TABLE songs_fts USING fts5(
  title,
  track_artist_id,
  album_id,
  content='songs',
  content_rowid='rowid'
);

CREATE TRIGGER songs_fts_after_insert AFTER INSERT ON songs BEGIN
  INSERT INTO songs_fts(rowid, title, track_artist_id, album_id)
  VALUES (new.rowid, new.title, new.track_artist_id, new.album_id);
END;

CREATE TRIGGER songs_fts_after_delete AFTER DELETE ON songs BEGIN
  INSERT INTO songs_fts(songs_fts, rowid, title, track_artist_id, album_id)
  VALUES ('delete', old.rowid, old.title, old.track_artist_id, old.album_id);
END;

CREATE TRIGGER songs_fts_after_update AFTER UPDATE ON songs BEGIN
  INSERT INTO songs_fts(songs_fts, rowid, title, track_artist_id, album_id)
  VALUES ('delete', old.rowid, old.title, old.track_artist_id, old.album_id);
  INSERT INTO songs_fts(rowid, title, track_artist_id, album_id)
  VALUES (new.rowid, new.title, new.track_artist_id, new.album_id);
END;
''';

/// Seeds a v14 database at [path] with a realistic, populated dataset:
/// 3 songs, 1 playlist containing all 3, 1 queue containing 3 (with a
/// duplicate), 2 history entries, 2 song interactions, 1 album
/// interaction, AND 1 already-orphaned playlist entry (song_id pointing
/// at a path that no longer exists — simulating the pre-T1 bug).
///
/// Setting `PRAGMA user_version = 14` is what tells Drift to run
/// `onUpgrade` the next time the database is opened.
void _seedV14Database(String path) {
  final raw = sqlite.sqlite3.open(path);
  try {
    raw.execute(_v14Ddl);
    raw.execute('PRAGMA user_version = 14');

    raw.execute('''
      INSERT INTO songs (id, title, track_artist_id, album_id, duration_ms,
        file_path, format, file_size_bytes, genre_names, date_added_utc_ms)
      VALUES
        ('/music/a.mp3', 'Song A', 'Artist 1', 'Album 1', 1000,
         '/music/a.mp3', 'mp3', 100, '', 0),
        ('/music/b.mp3', 'Song B', 'Artist 1', 'Album 1', 1000,
         '/music/b.mp3', 'mp3', 100, '', 0),
        ('/music/c.mp3', 'Song C', 'Artist 2', 'Album 2', 1000,
         '/music/c.mp3', 'mp3', 100, '', 0);
    ''');

    raw.execute('''
      INSERT INTO playlists (id, name, date_created_utc_ms)
      VALUES ('p1', 'Playlist 1', 0);
    ''');

    // 3 legit entries + 1 orphan (points at a path with no song row).
    raw.execute('''
      INSERT INTO playlist_songs (playlist_id, position, song_id)
      VALUES
        ('p1', 0, '/music/a.mp3'),
        ('p1', 1, '/music/b.mp3'),
        ('p1', 2, '/music/c.mp3'),
        ('p1', 3, '/music/ghost.mp3');
    ''');

    raw.execute('''
      INSERT INTO playback_queues (id, current_index, repeat_mode, source)
      VALUES ('q1', 0, 'off', '{"type":"manual"}');
    ''');

    raw.execute('''
      INSERT INTO queue_songs (queue_id, list_kind, position, song_id)
      VALUES
        ('q1', 'current', 0, '/music/a.mp3'),
        ('q1', 'current', 1, '/music/b.mp3'),
        ('q1', 'current', 2, '/music/a.mp3');
    ''');

    raw.execute('''
      INSERT INTO playback_history (song_id, timestamp_utc_ms)
      VALUES
        ('/music/a.mp3', 100),
        ('/music/b.mp3', 200);
    ''');

    raw.execute('''
      INSERT INTO item_interactions (item_id, item_type, interaction, timestamp_utc_ms)
      VALUES
        ('/music/a.mp3', 'song', 1, 100),
        ('/music/b.mp3', 'song', -1, 100),
        ('Some Album Name', 'album', 1, 100);
    ''');
  } finally {
    raw.close();
  }
}

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexo_migration_test_');
    dbFile = File(p.join(tempDir.path, 'nexo.sqlite'));
    _seedV14Database(dbFile.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('Schema 15 migration (v14 -> v15, foreign_keys OFF)', () {
    test(
        'migrates a populated v14 database without crashing and remaps '
        'every FK column to the new integer ids', () async {
      // Uses openConnection — the production factory. It sets WAL and
      // synchronous=NORMAL but does NOT enable foreign_keys, matching
      // the actual runtime the migration will run in.
      final db = AppDatabase(openConnection(dbFile));
      try {
        // Lazy-open: the migration runs on the first query.
        await db.customSelect('SELECT 1').get();

        // --- PRAGMA user_version bumped to 15 ---
        final version =
            await db.customSelect('PRAGMA user_version').getSingle();
        expect(version.data['user_version'], 15);

        // --- Songs: 3 rows, stable integer ids assigned ---
        final songs = await db.select(db.songs).get();
        expect(songs.length, 3);
        expect(songs.map((s) => s.id).toSet(), {1, 2, 3});
        expect(songs.map((s) => s.filePath).toSet(), {
          '/music/a.mp3',
          '/music/b.mp3',
          '/music/c.mp3',
        });

        // --- §7.1: verify rowid alias semantically ---
        // Using `_rowid_` (SQLite's reserved alias for the actual rowid,
        // unaffected by user-defined column names) with an explicit
        // result alias, so this check does not depend on how SQLite
        // names the rowid column in a bare `SELECT rowid` projection.
        final rowidCheck = await db
            .customSelect(
              'SELECT _rowid_ AS real_rowid, id AS user_id FROM songs ORDER BY id',
            )
            .get();
        expect(rowidCheck.length, 3);
        for (final row in rowidCheck) {
          expect(
            row.data['real_rowid'],
            row.data['user_id'],
            reason: 'INTEGER PRIMARY KEY must alias rowid. '
                'Row data was: ${row.data}',
          );
        }

        // --- playlist_songs: 3 rows (the orphan was dropped silently) ---
        final playlistRows = await db
            .customSelect(
              'SELECT playlist_id, position, song_id FROM playlist_songs '
              'ORDER BY position',
            )
            .get();
        expect(playlistRows.length, 3);
        final playlistSongIds =
            playlistRows.map((r) => r.data['song_id'] as int).toList();
        expect(playlistSongIds.toSet().length, 3);

        // --- queue_songs: duplicates preserved at distinct positions ---
        final queueRows = await db
            .customSelect(
              'SELECT song_id FROM queue_songs ORDER BY position',
            )
            .get();
        expect(queueRows.length, 3);
        final queueSongIds =
            queueRows.map((r) => r.data['song_id'] as int).toList();
        expect(queueSongIds[0], queueSongIds[2],
            reason: 'duplicate at positions 0 and 2 must survive');

        // --- playback_history: 2 rows, all remapped to ints ---
        final historyRows = await db
            .customSelect(
              'SELECT song_id FROM playback_history',
            )
            .get();
        expect(historyRows.length, 2);
        for (final row in historyRows) {
          expect(row.data['song_id'], isA<int>());
        }

        // --- item_interactions: song rows remapped; album row untouched ---
        final albumInteraction = await db
            .customSelect(
              "SELECT item_id FROM item_interactions WHERE item_type = 'album'",
            )
            .getSingle();
        expect(albumInteraction.data['item_id'], 'Some Album Name');

        final songInteractions = await db
            .customSelect(
              "SELECT item_id FROM item_interactions WHERE item_type = 'song'",
            )
            .get();
        expect(songInteractions.length, 2);
        for (final row in songInteractions) {
          final parsed = int.tryParse(row.data['item_id'] as String);
          expect(parsed, isNotNull,
              reason: 'song item_id must be an int serialized as TEXT');
          expect({1, 2}.contains(parsed), isTrue);
        }

        // --- FTS rebuilt against the new rowids ---
        final ftsCount = await db
            .customSelect(
              'SELECT COUNT(*) AS n FROM songs_fts',
            )
            .getSingle();
        expect(ftsCount.data['n'], 3);

        // --- FTS trigger wired to the NEW rowids: an insert propagates ---
        await db.customStatement('''
          INSERT INTO songs (
            title, track_artist_id, album_id, duration_ms, file_path,
            format, file_size_bytes, genre_names, date_added_utc_ms
          ) VALUES (
            'New Song', 'New Artist', 'New Album', 1000, '/music/new.mp3',
            'mp3', 100, '', 0
          );
        ''');
        final ftsAfter = await db
            .customSelect(
              'SELECT COUNT(*) AS n FROM songs_fts',
            )
            .getSingle();
        expect(ftsAfter.data['n'], 4);
      } finally {
        await db.close();
      }
    });

    // §7.6 — implicit: this test never calls CrashLogger.init(), so
    // `_logFile` is still uninitialized when _reportOrphansIfAny fires
    // (the seed has exactly 1 orphan in playlist_songs). The migration
    // reaching this point proves the logEvent try-catch swallowed the
    // LateInitializationError instead of aborting the transaction.
    test(
        'migration completes with an orphan present AND CrashLogger '
        'never initialized (late _logFile swallowed)', () async {
      final db = AppDatabase(openConnection(dbFile));
      try {
        await db.customSelect('SELECT 1').get();

        // The migration reached the post-commit state — no exception.
        final songs = await db.select(db.songs).get();
        expect(songs.length, 3);

        // The orphan was dropped from playlist_songs (4 -> 3).
        final refs = await db
            .customSelect(
              'SELECT COUNT(*) AS n FROM playlist_songs',
            )
            .getSingle();
        expect(refs.data['n'], 3);
      } finally {
        await db.close();
      }
    });
  });

  group('Schema 15 migration (v14 -> v15, foreign_keys ON)', () {
    test('migration also succeeds when foreign key enforcement is enabled',
        () async {
      // Stricter than current production: enables FK enforcement at the
      // connection level. This is NOT what the app does today (see
      // openConnection), but is the shape the migration would face if
      // enforcement is ever turned on. Result is documented in the PR,
      // not assumed.
      final db = AppDatabase(
        NativeDatabase(
          dbFile,
          setup: (raw) => raw.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      try {
        await db.customSelect('SELECT 1').get();

        final songs = await db.select(db.songs).get();
        expect(songs.length, 3);

        final refs = await db
            .customSelect(
              'SELECT COUNT(*) AS n FROM playlist_songs',
            )
            .getSingle();
        expect(refs.data['n'], 3);
      } finally {
        await db.close();
      }
    });
  });
}
