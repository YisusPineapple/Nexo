import 'package:drift/drift.dart';

import '../converters/audio_format_converter.dart';
import '../converters/string_list_converter.dart';

/// Drift table backing [Song]. A DTO/schema concern only — mapping
/// to/from the actual [Song] entity is [SongRepositoryImpl]'s job
/// (Sub-fase 2.2), never this file's.
///
/// [id] is TEXT (mirroring [SongId] directly), not an auto-increment
/// int: Domain already treats [SongId] as the stable identity used
/// everywhere else (playlists, queues), so a second surrogate id here
/// would just be a redundant join key every table below would have to
/// carry too.
@DataClassName('SongRow')
class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get trackArtistId => text()();
  TextColumn get albumArtistId => text().nullable()();
  TextColumn get albumId => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();

  /// [Duration] stored as whole milliseconds. Deliberately a plain
  /// int, not drift's dateTime()-style column sugar: this is a
  /// duration, not a point in time, and a plain int sidesteps any
  /// version-specific behavior in how drift's temporal columns pick
  /// their on-disk representation.
  IntColumn get durationMs => integer()();

  TextColumn get filePath => text()();
  TextColumn get format => text().map(const AudioFormatConverter())();
  IntColumn get fileSizeBytes => integer()();

  /// See [StringListConverter]'s docstring for why this is one column,
  /// not a join table.
  TextColumn get genreNames => text().map(const StringListConverter())();

  IntColumn get year => integer().nullable()();
  TextColumn get coverArtPath => text().nullable()();
  IntColumn get leadingSilenceMs => integer().withDefault(const Constant(0))();
  IntColumn get trailingSilenceMs => integer().withDefault(const Constant(0))();
  RealColumn get replayGainTrackDb => real().nullable()();
  RealColumn get replayGainAlbumDb => real().nullable()();

  /// Epoch milliseconds, UTC — see [durationMs]'s docstring for the
  /// same "plain int, not a temporal column type" reasoning.
  IntColumn get dateAddedUtcMs => integer()();

  BoolColumn get isMissing => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
