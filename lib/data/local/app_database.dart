import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../core/utils/crash_logger.dart';
import '../../domain/entities/audio_format.dart';
import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/queue_source.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../domain/entities/app_preferences.dart';
import 'converters/audio_format_converter.dart';
import 'converters/crossfade_mode_converter.dart';
import 'converters/queue_source_converter.dart';
import 'converters/repeat_mode_converter.dart';
import 'converters/string_list_converter.dart';
import 'converters/performance_profile_converter.dart';
import 'converters/app_theme_mode_converter.dart';
import 'converters/lyrics_alignment_converter.dart';
import 'converters/lyrics_font_size_converter.dart';
import 'tables/active_session_table.dart';
import 'tables/item_interactions_table.dart';
import 'tables/playback_history_table.dart';
import 'tables/playback_queues_table.dart';
import 'tables/playback_settings_table.dart';
import 'tables/playlist_songs_table.dart';
import 'tables/playlists_table.dart';
import 'tables/queue_songs_table.dart';
import 'tables/songs_table.dart';
import 'tables/app_preferences_table.dart';
import 'tables/indexed_folders_table.dart';
import 'tables/excluded_folders_table.dart';

part 'app_database.g.dart';

QueryExecutor openConnection(File file) {
  return NativeDatabase.createInBackground(
    file,
    setup: (db) {
      db.execute('PRAGMA journal_mode=WAL;');
      db.execute('PRAGMA synchronous=NORMAL;');
      // Note: PRAGMA foreign_keys is intentionally NOT set here. SQLite
      // defaults to OFF per-connection, which means the `references(...)`
      // clauses on the join tables are declarative only today. Enabling
      // enforcement is tracked as a separate ticket because it changes
      // the semantics of parent deletes elsewhere in the app.
    },
  );
}

@DriftDatabase(
  tables: [
    Songs,
    PlaybackQueues,
    QueueSongs,
    PlaybackSettingsTable,
    ActiveSessionTable,
    Playlists,
    PlaylistSongs,
    PlaybackHistory,
    ItemInteractions,
    AppPreferencesTable,
    IndexedFolders,
    ExcludedFolders,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createSearchSchema();
          await _createSortIndexes();
          await into(appPreferencesTable).insert(
            AppPreferencesTableCompanion.insert(
              id: const Value(0),
              isOnboardingCompleted: const Value(false),
              performanceProfile: PerformanceProfile.balanced,
              themeMode: AppThemeMode.system,
              lyricsAlignment: const Value(LyricsAlignment.center),
              lyricsFontSize: const Value(LyricsFontSize.medium),
              lyricsBlurEnabled: const Value(true),
              lyricsHighlightWords: const Value(true),
              useSystemFont: const Value(false),
            ),
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(playlists);
            await m.createTable(playlistSongs);
          }
          if (from < 3) {
            await m.createTable(playbackHistory);
            await m.createTable(itemInteractions);
          }
          if (from < 4) {
            await m.addColumn(
                playbackSettingsTable, playbackSettingsTable.isAutoDuration);
          }
          if (from < 5) {
            await m.createTable(appPreferencesTable);
            await into(appPreferencesTable).insert(
              AppPreferencesTableCompanion.insert(
                id: const Value(0),
                isOnboardingCompleted: const Value(false),
                performanceProfile: PerformanceProfile.balanced,
                themeMode: AppThemeMode.system,
                lyricsAlignment: const Value(LyricsAlignment.center),
                lyricsFontSize: const Value(LyricsFontSize.medium),
                lyricsBlurEnabled: const Value(true),
                lyricsHighlightWords: const Value(true),
                useSystemFont: const Value(false),
              ),
            );
          }
          if (from < 6) {
            await m.createTable(indexedFolders);
            await m.createTable(excludedFolders);
          }
          if (from < 7) {
            await m.addColumn(
                appPreferencesTable, appPreferencesTable.lyricsAlignment);
          }
          if (from < 8) {
            await m.addColumn(
                appPreferencesTable, appPreferencesTable.lyricsFontSize);
            await m.addColumn(
                appPreferencesTable, appPreferencesTable.lyricsBlurEnabled);
            await m.addColumn(
                appPreferencesTable, appPreferencesTable.lyricsHighlightWords);
          }
          if (from < 9) {
            await m.addColumn(songs, songs.lyricOffsetMs);
          }
          if (from < 10) {
            await m.addColumn(playbackQueues, playbackQueues.positionMs);
          }
          if (from < 11) {
            await m.addColumn(songs, songs.hasNoCover);
          }
          if (from < 12) {
            await _createSearchSchema();
            await _backfillFtsFromExistingSongs();
          }
          if (from < 13) {
            await m.addColumn(
                appPreferencesTable, appPreferencesTable.useSystemFont);
          }
          if (from < 14) {
            await m.addColumn(songs, songs.sectionKey);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_songs_section_key ON songs (section_key);',
            );
          }
          if (from < 15) {
            await _migrateToStableSongId(m);
          }
          if (from < 16) {
            await _createSortIndexes();
          }
          if (from < 17) {
            await _invalidateLegacyCoverCache();
          }
        },
      );

  /// Schema 17 migration: invalidates every cached cover art path.
  ///
  /// The pre-17 cover cache used `String.hashCode` as the filename key
  /// (see `song_repository_impl.dart`'s `_buildSong`). Dart's
  /// `String.hashCode` is NOT stable across isolates or across process
  /// restarts — the seed is per-isolate and per-process — so every
  /// cached path in the DB is untrustworthy: some point at files that
  /// were never written on this boot, others point at duplicates that
  /// were written by parallel extraction isolates, and every restart
  /// produced a fresh round of names. Full diagnosis in
  /// ARCHITECTURE.md §2.5.
  ///
  /// The fix (`computeCoverId` = SHA-256 over the raw cover bytes) makes
  /// new writes stable, but does nothing for the rows already in the DB.
  /// This migration resets them so the background extractor re-populates
  /// the table with SHA-256-keyed paths on the next cycle.
  ///
  /// WHERE cover_art_path IS NOT NULL is deliberate:
  ///   * A row with `has_no_cover = 1` already has `cover_art_path = NULL`
  ///     by invariant (the extractor writes both together). It will not
  ///     match the WHERE, so it is not re-queued for extraction — that
  ///     would waste I/O on songs we already know have no cover.
  ///   * A row with `cover_art_path = NULL` and `has_no_cover = 0` is
  ///     already scheduled by the extractor's normal cycle and needs no
  ///     help from this migration.
  ///   * A row with both `has_no_cover = 1` AND `cover_art_path IS NOT
  ///     NULL` is a pre-existing inconsistency (should not happen, but
  ///     has no invariant enforcing it). Clearing its cover path and
  ///     resetting `has_no_cover = 0` is the correct behavior: retry
  ///     extraction, because the mere existence of a path implies the
  ///     extractor once succeeded.
  ///
  /// Filesystem work is deliberately NOT part of this block. `onUpgrade`
  /// runs inside a SQL transaction and the filesystem is not party to
  /// it — if a later statement in the same transaction fails, the SQL
  /// rolls back but any file deletion would already have happened,
  /// leaving the DB pointing at covers that no longer exist. The cache
  /// purge is therefore a separate, post-commit, best-effort step in
  /// `main.dart` (Phase B), gated by a one-shot marker file.
  Future<void> _invalidateLegacyCoverCache() async {
    await customStatement(
      'UPDATE songs SET cover_art_path = NULL, has_no_cover = 0 '
      'WHERE cover_art_path IS NOT NULL;',
    );
  }

  /// Schema 15 migration: replaces the previous `SongId = file path` scheme
  /// with a stable `INTEGER PRIMARY KEY` assigned by SQLite.
  ///
  /// The strategy is drop-and-recreate rather than `ALTER TABLE`, because
  /// SQLite cannot change a column's type or add a UNIQUE constraint to an
  /// existing column without rebuilding the table. All dependent tables
  /// that carry a `song_id` reference are backed up to TEMP tables, dropped,
  /// recreated via Drift (so the DDL matches exactly what the regenerated
  /// schema expects), then re-populated against the new integer ids.
  ///
  /// Hard invariant: every step that is part of the migration itself (the
  /// reinserts in steps 5–7) is NOT wrapped in try-catch. If those fail,
  /// the transaction aborts and the migration is retried on the next
  /// launch — which is the correct behavior. Only the diagnostic helper
  /// ([_reportOrphansIfAny]) is fail-safe, because a diagnostic must never
  /// be able to abort the operation it is observing.
  Future<void> _migrateToStableSongId(Migrator m) async {
    await customStatement('PRAGMA defer_foreign_keys = ON;');

    await customStatement('''
      CREATE TEMP TABLE song_id_map AS
      SELECT id AS old_id, ROW_NUMBER() OVER (ORDER BY rowid) AS new_id
      FROM songs;
    ''');

    await customStatement(
      'CREATE TEMP TABLE songs_backup AS SELECT * FROM songs;',
    );
    await customStatement(
      'CREATE TEMP TABLE playlist_songs_backup AS SELECT * FROM playlist_songs;',
    );
    await customStatement(
      'CREATE TEMP TABLE queue_songs_backup AS SELECT * FROM queue_songs;',
    );
    await customStatement(
      'CREATE TEMP TABLE playback_history_backup AS SELECT * FROM playback_history;',
    );

    await customStatement('DROP TABLE playlist_songs;');
    await customStatement('DROP TABLE queue_songs;');
    await customStatement('DROP TABLE playback_history;');
    await customStatement('DROP TRIGGER IF EXISTS songs_fts_after_insert;');
    await customStatement('DROP TRIGGER IF EXISTS songs_fts_after_delete;');
    await customStatement('DROP TRIGGER IF EXISTS songs_fts_after_update;');
    await customStatement('DROP TABLE IF EXISTS songs_fts;');
    await customStatement('DROP TABLE songs;');

    await m.createTable(songs);
    await m.createTable(playlistSongs);
    await m.createTable(queueSongs);
    await m.createTable(playbackHistory);

    await customStatement('''
      INSERT INTO songs (
        id, title, track_artist_id, album_artist_id, album_id,
        track_number, disc_number, duration_ms, file_path, format,
        file_size_bytes, genre_names, year, cover_art_path,
        leading_silence_ms, trailing_silence_ms, replay_gain_track_db,
        replay_gain_album_db, date_added_utc_ms, is_missing,
        lyric_offset_ms, has_no_cover, section_key
      )
      SELECT
        m.new_id, s.title, s.track_artist_id, s.album_artist_id, s.album_id,
        s.track_number, s.disc_number, s.duration_ms, s.file_path, s.format,
        s.file_size_bytes, s.genre_names, s.year, s.cover_art_path,
        s.leading_silence_ms, s.trailing_silence_ms, s.replay_gain_track_db,
        s.replay_gain_album_db, s.date_added_utc_ms, s.is_missing,
        s.lyric_offset_ms, s.has_no_cover, s.section_key
      FROM songs_backup s
      JOIN song_id_map m ON m.old_id = s.id;
    ''');

    await customStatement('''
      INSERT INTO playlist_songs (playlist_id, position, song_id)
      SELECT pb.playlist_id, pb.position, m.new_id
      FROM playlist_songs_backup pb
      JOIN song_id_map m ON m.old_id = pb.song_id;
    ''');
    await _reportOrphansIfAny('playlist_songs');

    await customStatement('''
      INSERT INTO queue_songs (queue_id, list_kind, position, song_id)
      SELECT qb.queue_id, qb.list_kind, qb.position, m.new_id
      FROM queue_songs_backup qb
      JOIN song_id_map m ON m.old_id = qb.song_id;
    ''');
    await _reportOrphansIfAny('queue_songs');

    await customStatement('''
      INSERT INTO playback_history (id, song_id, timestamp_utc_ms)
      SELECT phb.id, m.new_id, phb.timestamp_utc_ms
      FROM playback_history_backup phb
      JOIN song_id_map m ON m.old_id = phb.song_id;
    ''');
    await _reportOrphansIfAny('playback_history');

    await customStatement('''
      UPDATE item_interactions
      SET item_id = (
        SELECT m.new_id FROM song_id_map m
        WHERE m.old_id = item_interactions.item_id
      )
      WHERE item_type = 'song'
        AND EXISTS (
          SELECT 1 FROM song_id_map m
          WHERE m.old_id = item_interactions.item_id
        );
    ''');

    await _createSearchSchema();
    await _backfillFtsFromExistingSongs();
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_section_key ON songs (section_key);',
    );

    await customStatement('DROP TABLE song_id_map;');
    await customStatement('DROP TABLE songs_backup;');
    await customStatement('DROP TABLE playlist_songs_backup;');
    await customStatement('DROP TABLE queue_songs_backup;');
    await customStatement('DROP TABLE playback_history_backup;');
  }

  /// Compares row counts of `<table>_backup` against `<table>` and writes an
  /// informational line to the crash log if any row was dropped because its
  /// old TEXT song id no longer matched a song in the new schema.
  ///
  /// Fail-safe on purpose: this helper is invoked from inside the schema 15
  /// migration's transaction, and a diagnostic must NEVER be able to abort
  /// the operation it is observing. Any exception (SQL syntax error, type
  /// mismatch on the COUNT result, or a `LateInitializationError` from
  /// [CrashLogger] if `init()` was never called) is swallowed.
  Future<void> _reportOrphansIfAny(String table) async {
    try {
      final row = await customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM ${table}_backup) - '
        '(SELECT COUNT(*) FROM $table) AS n',
      ).getSingle();
      final n = row.data['n'] as int;
      if (n > 0) {
        CrashLogger.logEvent(
          'migration.v15',
          '$n row(s) in $table referenced a song id that no longer exists '
              'and were dropped during the schema 15 migration. These entries '
              'were already orphaned before the migration (the pre-T1 SongId '
              'was the file path).',
        );
      }
    } catch (_) {
      // Diagnostics must never abort the migration they are observing.
    }
  }

  Future<void> _createSearchSchema() async {
    await customStatement('''
CREATE VIRTUAL TABLE IF NOT EXISTS songs_fts USING fts5(
  title,
  track_artist_id,
  album_id,
  content='songs',
  content_rowid='rowid'
);
''');

    await customStatement('''
CREATE TRIGGER IF NOT EXISTS songs_fts_after_insert AFTER INSERT ON songs BEGIN
  INSERT INTO songs_fts(rowid, title, track_artist_id, album_id)
  VALUES (new.rowid, new.title, new.track_artist_id, new.album_id);
END;
''');

    await customStatement('''
CREATE TRIGGER IF NOT EXISTS songs_fts_after_delete AFTER DELETE ON songs BEGIN
  INSERT INTO songs_fts(songs_fts, rowid, title, track_artist_id, album_id)
  VALUES ('delete', old.rowid, old.title, old.track_artist_id, old.album_id);
END;
''');

    await customStatement('''
CREATE TRIGGER IF NOT EXISTS songs_fts_after_update AFTER UPDATE ON songs BEGIN
  INSERT INTO songs_fts(songs_fts, rowid, title, track_artist_id, album_id)
  VALUES ('delete', old.rowid, old.title, old.track_artist_id, old.album_id);
  INSERT INTO songs_fts(rowid, title, track_artist_id, album_id)
  VALUES (new.rowid, new.title, new.track_artist_id, new.album_id);
END;
''');

    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_album_id ON songs (album_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_track_artist_id '
      'ON songs (track_artist_id);',
    );
  }

  Future<void> _backfillFtsFromExistingSongs() async {
    await customStatement('''
INSERT INTO songs_fts(rowid, title, track_artist_id, album_id)
SELECT rowid, title, track_artist_id, album_id FROM songs;
''');
  }

  /// Schema 16 migration: adds functional and plain indexes for every column
  /// used by [SongRepository.watchSongsWindow]'s ORDER BY.
  ///
  /// `LOWER(title)`, `LOWER(track_artist_id)`, `LOWER(album_id)` are
  /// functional indexes (SQLite ≥ 3.9.0) — the LOWER transform means the
  /// existing plain-column indexes on `album_id` and `track_artist_id` do
  /// NOT cover `ORDER BY LOWER(col)` queries. Without these, LIMIT/OFFSET
  /// pagination over 15k rows costs 24–38 ms per page on the dev box; with
  /// them, 1.1 ms. Measured in Sprint9_P0_T2.md §5.1 and §5.3.
  ///
  /// `year`, `duration_ms`, `date_added_utc_ms` are plain int columns with
  /// no LOWER() transform — the indexes are standard B-trees. They are
  /// included because the same OFFSET-over-sort cost applies to those sorts.
  ///
  /// `ANALYZE` updates the query planner's statistics so SQLite actually
  /// picks these indexes on the next query. Without it, a fresh migration on
  /// a DB that has never been analyzed can leave the planner with no stats
  /// for these columns and it may fall back to a full scan.
  ///
  /// Idempotent: all `CREATE INDEX` statements use `IF NOT EXISTS`, so
  /// calling this from both `onCreate` (fresh install at v16) and
  /// `onUpgrade(from < 16)` is safe — a fresh install reaches the same end
  /// state as an upgraded install.
  Future<void> _createSortIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_title_lower '
      'ON songs (LOWER(title));',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_artist_lower '
      'ON songs (LOWER(track_artist_id));',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_album_lower '
      'ON songs (LOWER(album_id));',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_year ON songs (year);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_duration ON songs (duration_ms);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_date_added '
      'ON songs (date_added_utc_ms);',
    );

    await customStatement('ANALYZE;');
  }
}
