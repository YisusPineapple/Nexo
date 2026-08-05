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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2; // <--- INCREMENTADO A 2

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Migración de v1 a v2: Crear las tablas de Playlists
            await m.createTable(playlists);
            await m.createTable(playlistSongs);
          }
        },
      );
}