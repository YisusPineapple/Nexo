import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'data/local/app_database.dart';
import 'presentation/providers/repository_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registers the media_kit backend so just_audio actually has a
  // native engine on Linux/Windows — see this turn's note on why this
  // is required (just_audio has no built-in engine on those two
  // platforms, unlike Android/iOS/macOS).
  JustAudioMediaKit.ensureInitialized();

  final supportDir = await getApplicationSupportDirectory();
  final dbFile = File(p.join(supportDir.path, 'nexo.sqlite'));
  final coverArtDir = p.join(supportDir.path, 'covers');

  final database = AppDatabase(openConnection(dbFile));

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        coverArtCacheDirectoryProvider.overrideWithValue(coverArtDir),
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
      theme: ThemeData(
        useMaterial3: true,
        // Placeholder seed — el "tema cálido" real se define en 3.10.
        colorSchemeSeed: Colors.deepOrange,
      ),
      home: const _WiringCheckScreen(),
    );
  }
}

/// Temporary Sub-fase 3.1 screen: proves DB -> repositories are wired
/// end to end, AND that the just_audio/media_kit fix actually works,
/// before any real navigation or library UI exists (that's 3.2/3.3).
/// Delete once 3.2 lands.
class _WiringCheckScreen extends ConsumerWidget {
  const _WiringCheckScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching this alone constructs AudioPlayerRepositoryImpl() right
    // now — the first time just_audio's native backend gets exercised
    // anywhere in this project (Sub-fase 2.4's tests couldn't reach
    // it; see that phase's own notes). If media_kit isn't wired
    // correctly, this throws immediately and visibly right here.
    ref.watch(audioPlayerRepositoryProvider);

    final songRepo = ref.watch(songRepositoryProvider);
    return Scaffold(
      body: Center(
        child: FutureBuilder(
          future: songRepo.getAllSongs(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final result = snapshot.data!;
            return Text(
              result.when(
                ok: (songs) =>
                    'Wiring OK — ${songs.length} songs indexed. '
                    'Audio engine constructed without throwing.',
                err: (e) =>
                    'Wiring reached the repo but got a Failure: ${e.message}',
              ),
            );
          },
        ),
      ),
    );
  }
}