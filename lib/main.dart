import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'data/audio/nexo_audio_handler.dart';
import 'data/local/app_database.dart';
import 'presentation/providers/repository_providers.dart';
import 'presentation/screens/home_shell.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();

  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024;

  final supportDir = await getApplicationSupportDirectory();
  final dbFile = File(p.join(supportDir.path, 'nexo.sqlite'));
  final coverArtDir = p.join(supportDir.path, 'covers');

  final database = AppDatabase(openConnection(dbFile));

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
      ],
      child: const NexoApp(),
    ),
  );
}

class NexoApp extends StatelessWidget {
  const NexoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Adapts to OS settings automatically
      home: const HomeShell(),
    );
  }
}