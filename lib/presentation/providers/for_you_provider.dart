import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import 'repository_providers.dart';

/// Data model for the For You screen.
class ForYouData {
  const ForYouData({
    required this.recentlyPlayed,
    required this.topTracks,
    required this.dailyMix,
  });

  final List<Song> recentlyPlayed;
  final List<Song> topTracks;
  final List<Song> dailyMix;

  bool get isEmpty =>
      recentlyPlayed.isEmpty && topTracks.isEmpty && dailyMix.isEmpty;
}

/// Controller for the For You screen.
class ForYouController extends AsyncNotifier<ForYouData> {
  @override
  Future<ForYouData> build() async {
    final metricsRepo = ref.watch(userMetricsRepositoryProvider);

    final results = await Future.wait([
      metricsRepo.getRecentlyPlayed(),
      metricsRepo.getTopTracks(),
      metricsRepo.getDailyMix(),
    ]);

    final recentlyPlayed = results[0].when(
      ok: (v) => v,
      err: (e) => throw e,
    );
    final topTracks = results[1].when(
      ok: (v) => v,
      err: (e) => throw e,
    );
    final dailyMix = results[2].when(
      ok: (v) => v,
      err: (e) => throw e,
    );

    return ForYouData(
      recentlyPlayed: recentlyPlayed,
      topTracks: topTracks,
      dailyMix: dailyMix,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Provider for the For You controller.
final forYouControllerProvider =
    AsyncNotifierProvider<ForYouController, ForYouData>(
  ForYouController.new,
);