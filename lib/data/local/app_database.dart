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
import 'tables/item_interactions_table.dart';
import 'tables/playback_history_table.dart';
import 'tables/playback_queues_table.dart';
import 'tables/playback_settings_table.dart';
import 'tables/playlist_songs_table.dart';
import 'tables/playlists_table.dart';
import 'tables/queue_songs_table.dart';
import 'tables/songs_table.dart';

part 'app_database.g.dart';

QueryExecutor openConnection(File file) {
  return NativeDatabase.createInBackground(file);
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4; // <--- BUMPED TO 4

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
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
            // Migration to v4: Add isAutoDuration column
            await m.addColumn(
                playbackSettingsTable, playbackSettingsTable.isAutoDuration);
          }
        },
      );
}
