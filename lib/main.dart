import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/utils/crash_logger.dart';
import 'data/audio/nexo_audio_handler.dart';
import 'data/local/app_database.dart';
import 'data/repositories/app_preferences_repository_impl.dart';
import 'domain/entities/app_preferences.dart';
import 'presentation/providers/app_preferences_provider.dart';
import 'presentation/providers/repository_providers.dart';
import 'presentation/screens/home_shell.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    final supportDir = await getApplicationSupportDirectory();

    // Initialize offline crash reporting
    CrashLogger.init(supportDir.path);

    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: true,
      android: false,
      iOS: false,
      macOS: false,
    );

    final dbFile = File(p.join(supportDir.path, 'nexo.sqlite'));
    final coverArtDir = p.join(supportDir.path, 'covers');

    final database = AppDatabase(openConnection(dbFile));

    // Reading prefs here forces Drift to lazily open the database and run
    // its migration on first query. Any post-migration filesystem side
    // effect MUST come after this point — see the T3 Phase B call below.
    final prefsRepo = AppPreferencesRepositoryImpl(database);
    final prefsResult = await prefsRepo.getPreferences();
    final initialPrefs = prefsResult.valueOrNull ?? AppPreferences.defaults;

    // T3 Phase B: purge the legacy cover art cache after the schema 16 → 17
    // migration has landed. This is filesystem work deliberately kept OUT of
    // the Drift migration (SQL transactions don't cover the filesystem — see
    // the `if (from < 17)` block in `app_database.dart`). One-shot via a
    // marker file: running it on every boot would delete covers that a scan
    // has legitimately regenerated, leaving the DB pointing at missing
    // files. Best-effort: never aborts the app.
    await _purgeLegacyCoverCacheOnce(
      coverArtDir: coverArtDir,
      supportDir: supportDir.path,
    );

    if (initialPrefs.performanceProfile == PerformanceProfile.eco) {
      PaintingBinding.instance.imageCache.maximumSizeBytes = 15 * 1024 * 1024;
    } else {
      PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024;
    }

    final NexoAudioHandler audioHandler;
    if (Platform.isAndroid || Platform.isIOS) {
      audioHandler = await AudioService.init(
        builder: () => NexoAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'io.github.yisus.nexo.channel.audio.v7',
          androidNotificationChannelName: 'Nexo Music Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

      audioHandler.init();
    } else {
      audioHandler = NexoAudioHandler();
      audioHandler.init();
    }

    runApp(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appSupportDirectoryProvider.overrideWithValue(supportDir.path),
          coverArtCacheDirectoryProvider.overrideWithValue(coverArtDir),
          audioHandlerProvider.overrideWithValue(audioHandler),
          appPreferencesProvider
              .overrideWith(() => AppPreferencesNotifier(initialPrefs)),
        ],
        child: const NexoApp(),
      ),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                'FATAL INITIALIZATION ERROR:\n\n$e\n\n$stackTrace',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-shot wrapper around [_purgeCoverArtCache].
///
/// The schema 16 → 17 migration nulls every `cover_art_path` in the DB, so
/// only the FIRST boot after that migration actually needs the on-disk
/// cache wiped — subsequent boots must NOT re-purge, because by then a
/// scan may have legitimately regenerated SHA-256-keyed covers whose
/// paths the DB is now pointing at.
///
/// The marker file lives beside the database, in the app support
/// directory. It is intentionally a plain file, not a row in the DB: the
/// purge is a filesystem concern, and adding state to [AppDatabase] would
/// couple the persistence layer to filesystem paths (see AGENTS.md §2 on
/// the isolation this project enforces).
Future<void> _purgeLegacyCoverCacheOnce({
  required String coverArtDir,
  required String supportDir,
}) async {
  final marker = File(p.join(supportDir, 'cover_cache.v17.purged'));

  try {
    if (await marker.exists()) {
      return;
    }
  } catch (e) {
    // If we cannot even stat the marker, fall through and attempt the
    // purge anyway — worst case we purge a second time on next boot.
    CrashLogger.logEvent(
      'cover_cache.purge_marker_stat_failed',
      'Could not stat purge marker at ${marker.path}: $e',
    );
  }

  await _purgeCoverArtCache(coverArtDir);

  try {
    await marker.writeAsString(
      'purged_at=${DateTime.now().toUtc().toIso8601String()}\n',
    );
  } catch (e) {
    CrashLogger.logEvent(
      'cover_cache.purge_marker_write_failed',
      'Could not write purge marker at ${marker.path}: $e',
    );
  }
}

/// Best-effort delete of the cover art cache directory.
///
/// NEVER throws: a failure to purge the cache must never abort the app.
/// Idempotent on a missing directory (returns without logging an error).
/// Also mirrors what Settings → "Clear Cover Art Cache" does — same
/// behavior, same fail-safe posture.
Future<void> _purgeCoverArtCache(String directoryPath) async {
  try {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      return;
    }
    await dir.delete(recursive: true);
    CrashLogger.logEvent(
      'cover_cache.purge',
      'Legacy cover art cache purged at $directoryPath.',
    );
  } catch (e) {
    CrashLogger.logEvent(
      'cover_cache.purge_failed',
      'Failed to purge cover art cache at $directoryPath: $e',
    );
  }
}

class NexoApp extends ConsumerWidget {
  const NexoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);

    final themeMode = switch (prefs.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Nexo',
      debugShowCheckedModeBanner: false,
      // FIX: Apply useSystemFont dynamically based on user preferences
      theme: AppTheme.lightTheme(useSystemFont: prefs.useSystemFont),
      darkTheme: AppTheme.darkTheme(useSystemFont: prefs.useSystemFont),
      themeMode: themeMode,
      home: prefs.isOnboardingCompleted
          ? const HomeShell()
          : const OnboardingScreen(),
    );
  }
}
