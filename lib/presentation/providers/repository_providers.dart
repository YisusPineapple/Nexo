import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/audio/audio_player_repository_impl.dart';
import '../../data/audio/nexo_audio_handler.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/playback_repository_impl.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../data/repositories/user_metrics_repository_impl.dart';
import '../../data/repositories/app_preferences_repository_impl.dart';
import '../../domain/repositories/audio_player_repository.dart';
import '../../domain/repositories/playback_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/repositories/user_metrics_repository.dart';
import '../../domain/repositories/app_preferences_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in main()');
});

final coverArtCacheDirectoryProvider = Provider<String>((ref) {
  throw UnimplementedError(
    'coverArtCacheDirectoryProvider must be overridden in main()',
  );
});

final audioHandlerProvider = Provider<NexoAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main()');
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepositoryImpl(
    ref.watch(appDatabaseProvider),
    coverArtCacheDirectory: ref.watch(coverArtCacheDirectoryProvider),
  );
});

final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  return PlaybackRepositoryImpl(ref.watch(appDatabaseProvider));
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl(ref.watch(appDatabaseProvider));
});

final userMetricsRepositoryProvider = Provider<UserMetricsRepository>((ref) {
  return UserMetricsRepositoryImpl(ref.watch(appDatabaseProvider));
});

final audioPlayerRepositoryProvider = Provider<AudioPlayerRepository>((ref) {
  final repo = AudioPlayerRepositoryImpl(ref.watch(audioHandlerProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final appPreferencesRepositoryProvider = Provider<AppPreferencesRepository>((ref) {
  return AppPreferencesRepositoryImpl(ref.watch(appDatabaseProvider));
});