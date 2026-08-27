import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: true,
      android: false,
      iOS: false,
      macOS: false,
    );

    final supportDir = await getApplicationSupportDirectory();
    final dbFile = File(p.join(supportDir.path, 'nexo.sqlite'));
    final coverArtDir = p.join(supportDir.path, 'covers');

    final database = AppDatabase(openConnection(dbFile));

    final prefsRepo = AppPreferencesRepositoryImpl(database);
    final prefsResult = await prefsRepo.getPreferences();
    final initialPrefs = prefsResult.valueOrNull ?? AppPreferences.defaults;

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
          androidNotificationChannelId: 'io.github.yisus.nexo.channel.audio.v5',
          androidNotificationChannelName: 'Nexo Music Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidShowNotificationBadge: true,
          androidNotificationIcon: 'drawable/ic_notification', 
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: prefs.isOnboardingCompleted
          ? const HomeShell()
          : const OnboardingScreen(),
    );
  }
}
