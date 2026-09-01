import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/playback_queue.dart';
import 'repository_providers.dart';

final queueManagerControllerProvider =
    AsyncNotifierProvider<QueueManagerController, List<PlaybackQueue>>(
  QueueManagerController.new,
);

class QueueManagerController extends AsyncNotifier<List<PlaybackQueue>> {
  @override
  Future<List<PlaybackQueue>> build() async {
    final repo = ref.watch(playbackRepositoryProvider);
    final result = await repo.getAllQueues();
    return result.when(
      ok: (queues) => queues,
      err: (e) => throw e,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
