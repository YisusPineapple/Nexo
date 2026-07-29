import 'package:drift/drift.dart';

import '../converters/crossfade_mode_converter.dart';

/// Engine-wide [PlaybackSettings] — deliberately a single-row table,
/// mirroring how Domain models it as one global value, never
/// per-queue (see that entity's own docstring).
///
/// Named with a `Table` suffix (not just `PlaybackSettings`) because
/// the Domain entity is already called exactly that — reusing the
/// name here would be a hard import collision in any file that needs
/// both (the future settings-repository implementation, for one).
@DataClassName('PlaybackSettingsRow')
class PlaybackSettingsTable extends Table {
  /// Always 0. Not a real identity — just the row-selector that makes
  /// "there's only ever one settings row" an enforceable invariant
  /// ([primaryKey]) instead of a convention the repository has to
  /// remember to honor by itself.
  IntColumn get id => integer().withDefault(const Constant(0))();

  TextColumn get crossfadeMode => text().map(const CrossfadeModeConverter())();
  IntColumn get crossfadeDurationMs => integer()();

  /// Mirrors [PlaybackSpeed.speedHundredths] exactly (100 == 1.0x) —
  /// see that entity's docstring on why speed is stored as int
  /// hundredths rather than a raw double, to avoid tolerance-based
  /// equality on floating point.
  IntColumn get speedHundredths => integer()();
  BoolColumn get pitchCorrectionEnabled => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}
