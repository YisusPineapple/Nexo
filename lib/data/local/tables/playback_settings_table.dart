import 'package:drift/drift.dart';

import '../converters/crossfade_mode_converter.dart';

@DataClassName('PlaybackSettingsRow')
class PlaybackSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  TextColumn get crossfadeMode => text().map(const CrossfadeModeConverter())();
  IntColumn get crossfadeDurationMs => integer()();

  /// NEW: Stores whether the user selected Auto or Manual duration
  BoolColumn get isAutoDuration =>
      boolean().withDefault(const Constant(false))();

  IntColumn get speedHundredths => integer()();
  BoolColumn get pitchCorrectionEnabled => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}
