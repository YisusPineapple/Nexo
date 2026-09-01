import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

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
    AppPreferencesTable,
    IndexedFolders,
    ExcludedFolders,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
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
            await m.addColumn(playbackSettingsTable, playbackSettingsTable.isAutoDuration);
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
              ),
            );
          }
          if (from < 6) {
            await m.createTable(indexedFolders);
            await m.createTable(excludedFolders);
          }
          if (from < 7) {
            await m.addColumn(appPreferencesTable, appPreferencesTable.lyricsAlignment);
          }
          if (from < 8) {
            await m.addColumn(appPreferencesTable, appPreferencesTable.lyricsFontSize);
            await m.addColumn(appPreferencesTable, appPreferencesTable.lyricsBlurEnabled);
            await m.addColumn(appPreferencesTable, appPreferencesTable.lyricsHighlightWords);
          }
          if (from < 9) {
            await m.addColumn(songs, songs.lyricOffsetMs);
          }
          if (from < 10) {
            await m.addColumn(playbackQueues, playbackQueues.positionMs);
          }
        },
      );
}