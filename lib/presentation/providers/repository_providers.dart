import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/audio/audio_player_repository_impl.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/playback_repository_impl.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../domain/repositories/audio_player_repository.dart';
import '../../domain/repositories/playback_repository.dart';
import '../../domain/repositories/song_repository.dart';

/// Both of these MUST be overridden in main() after the async bootstrap
/// (resolving the support directory, opening [AppDatabase]) completes.
/// Left as an UnimplementedError rather than a nullable/late field so a
/// missed override at the composition root fails loudly on first read,
/// not with a silent null somewhere deep in a widget tree.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in main()');
});

final coverArtCacheDirectoryProvider = Provider<String>((ref) {
  throw UnimplementedError(
    'coverArtCacheDirectoryProvider must be overridden in main()',
  );
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

/// Typed as the Domain interface (DIP) even though the concrete
/// [AudioPlayerRepositoryImpl] instance underneath owns native
/// just_audio resources — [ref.onDispose] closes over that concrete
/// instance directly, so callers of this provider never need to know
/// disposal exists at all.
final audioPlayerRepositoryProvider = Provider<AudioPlayerRepository>((ref) {
  final repo = AudioPlayerRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});