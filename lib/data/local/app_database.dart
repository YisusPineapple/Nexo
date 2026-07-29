import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../domain/entities/audio_format.dart';
import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/queue_source.dart';
import '../../domain/entities/repeat_mode.dart';
import 'converters/audio_format_converter.dart';
import 'converters/crossfade_mode_converter.dart';
import 'converters/queue_source_converter.dart';
import 'converters/repeat_mode_converter.dart';
import 'converters/string_list_converter.dart';
import 'tables/active_session_table.dart';
import 'tables/playback_queues_table.dart';
import 'tables/playback_settings_table.dart';
import 'tables/queue_songs_table.dart';
import 'tables/songs_table.dart';

part 'app_database.g.dart';

/// Opens the on-disk database for real (non-test) use, running SQLite
/// itself in a background isolate via
/// [NativeDatabase.createInBackground] — this is Data layer's concrete
/// answer to PARTE A's "todo I/O pesado... en Isolates" restriction,
/// satisfied by drift itself rather than by hand-rolled isolate
/// plumbing around every query.
///
/// Takes a plain [File] instead of resolving a path itself (e.g. via
/// path_provider): path_provider is a Flutter plugin, and this whole
/// file is deliberately Flutter-free (see Sub-fase 2.1's rollout
/// notes) so it stays testable with plain `dart test`. Whichever
/// composition root wires this up in production is where
/// OS-specific path resolution belongs.
QueryExecutor openConnection(File file) {
  return NativeDatabase.createInBackground(file);
}

/// NOTE: every type referenced only by a [TypeConverter] (the enum
/// itself and the converter class) has to be imported directly in
/// THIS file, even though the tables that declare those columns
/// already import them too — app_database.g.dart is a `part` of this
/// library, so it only sees what's imported right here, never what a
/// table file imported on its own.
@DriftDatabase(
  tables: [
    Songs,
    PlaybackQueues,
    QueueSongs,
    PlaybackSettingsTable,
    ActiveSessionTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Takes a [QueryExecutor] rather than opening a file itself, so
  /// tests can pass [NativeDatabase.memory()] and production code can
  /// pass [openConnection] — this class doesn't need to know which.
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
      );
}
