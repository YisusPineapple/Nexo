import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();

  final supportDir = await getApplicationSupportDirectory();
  final dbFile = File(p.join(supportDir.path, 'nexo.sqlite'));
  final coverArtDir = p.join(supportDir.path, 'covers');

  final database = AppDatabase(openConnection(dbFile));

  // Fetch preferences synchronously before runApp to avoid UI flicker
  final prefsRepo = AppPreferencesRepositoryImpl(database);
  final prefsResult = await prefsRepo.getPreferences();
  final initialPrefs = prefsResult.valueOrNull ?? AppPreferences.defaults;

  // Apply ECO profile impact on ImageCache
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
        androidNotificationChannelId: 'com.example.nexo.channel.audio',
        androidNotificationChannelName: 'Nexo Music Playback',
        androidNotificationOngoing: true,
      ),
    );
  } else {
    audioHandler = NexoAudioHandler();
  }

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        coverArtCacheDirectoryProvider.overrideWithValue(coverArtDir),
        audioHandlerProvider.overrideWithValue(audioHandler),
        appPreferencesProvider.overrideWith(() => AppPreferencesNotifier(initialPrefs)),
      ],
      child: const NexoApp(),
    ),
  );
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