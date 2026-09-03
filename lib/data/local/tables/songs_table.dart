import 'package:drift/drift.dart';

import '../converters/audio_format_converter.dart';
import '../converters/string_list_converter.dart';

@DataClassName('SongRow')
class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get trackArtistId => text()();
  TextColumn get albumArtistId => text().nullable()();
  TextColumn get albumId => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();

  IntColumn get durationMs => integer()();

  TextColumn get filePath => text()();
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

  @override
  Set<Column> get primaryKey => {id};
}
