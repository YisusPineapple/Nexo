import 'package:drift/drift.dart';

import '../converters/audio_format_converter.dart';
import '../converters/string_list_converter.dart';

@DataClassName('SongRow')
class Songs extends Table {
  /// Stable, opaque identity for this song, assigned by SQLite as the
  /// table's rowid alias. This is an INTEGER PRIMARY KEY without the
  /// AUTOINCREMENT keyword on purpose: SQLite may recycle rowids after a
  /// hard DELETE, and the entire app is designed around never hard-deleting
  /// songs from this table — missing files are flagged via [isMissing]
  /// instead, so no rowid is ever freed.
  ///
  /// Do not hard-delete rows from this table. If a hard-delete feature is
  /// ever added, revisit AUTOINCREMENT first.
  ///
  /// Additionally, foreign key enforcement is currently OFF at the
  /// connection level (see `openConnection` in `app_database.dart`: only
  /// `journal_mode` and `synchronous` are configured). The `references(...)`
  /// clauses on `playlist_songs.song_id`, `queue_songs.song_id` and
  /// `playback_history.song_id` therefore generate DDL but are not validated
  /// by SQLite at runtime today. If `PRAGMA foreign_keys = ON` is ever
  /// enabled (separate ticket), the no-hard-delete premise becomes even
  /// more important, because SQLite would then reject deletes of referenced
  /// rows outright.
  IntColumn get id => integer()();

  TextColumn get title => text()();
  TextColumn get trackArtistId => text()();
  TextColumn get albumArtistId => text().nullable()();
  TextColumn get albumId => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();

  IntColumn get durationMs => integer()();

  /// UNIQUE on purpose: the file path is the upsert key for the scanner.
  /// A rescan of an existing folder matches on this column (via
  /// `DoUpdate(target: [songs.filePath])`) and updates the existing row
  /// in place, preserving its stable [id]. Without this constraint SQLite
  /// cannot resolve the upsert target and every rescan would insert a new
  /// row per file instead of updating the existing one.
  TextColumn get filePath => text().unique()();

  TextColumn get format => text().map(const AudioFormatConverter())();
  IntColumn get fileSizeBytes => integer()();

  TextColumn get genreNames => text().map(const StringListConverter())();

  IntColumn get year => integer().nullable()();
  TextColumn get coverArtPath => text().nullable()();
  IntColumn get leadingSilenceMs => integer().withDefault(const Constant(0))();
  IntColumn get trailingSilenceMs => integer().withDefault(const Constant(0))();
  RealColumn get replayGainTrackDb => real().nullable()();
  RealColumn get replayGainAlbumDb => real().nullable()();

  IntColumn get dateAddedUtcMs => integer()();

  BoolColumn get isMissing => boolean().withDefault(const Constant(false))();

  IntColumn get lyricOffsetMs => integer().withDefault(const Constant(0))();

  BoolColumn get hasNoCover => boolean().withDefault(const Constant(false))();

  // Pre-computed alphabetical section key ('A', 'B', ..., '#') used by the
  // alphabetical scroll rail so that grouping happens in SQL instead of
  // Dart. Populated at scan time by the repository.
  TextColumn get sectionKey => text().withDefault(const Constant('#'))();

  @override
  Set<Column> get primaryKey => {id};
}
