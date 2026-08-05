import 'dart:io';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/domain/entities/repeat_mode.dart';

import '../providers/playback_providers.dart';
import 'queue_screen.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playbackControllerProvider).valueOrNull;
    final isPlaying = ref.watch(playingStreamProvider).valueOrNull ?? false;
    final position =
        ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;

    final currentSong = queue?.currentSong;

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('No active playback')),
      );
    }

    final duration = currentSong.duration;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Now Playing',
          style: theme.textTheme.titleSmall,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Playback Queue',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QueueScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cover Art
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: currentSong.coverArtPath != null
                    ? Image.file(
                        File(currentSong.coverArtPath!),
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                      )
                    : const Icon(Icons.music_note, size: 100),
              ),
            ),
            const SizedBox(height: 48),

            // Metadata
            Text(
              currentSong.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              currentSong.trackArtistId.value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),

            // Progress Bar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: position.inMilliseconds
                    .toDouble()
                    .clamp(0, duration.inMilliseconds.toDouble()),
                max: duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  ref.read(playbackControllerProvider.notifier).seekTo(
                        Duration(milliseconds: value.toInt()),
                      );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    _formatDuration(duration),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  color: queue!.shuffleEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  onPressed: () {
                    ref
                        .read(playbackControllerProvider.notifier)
                        .toggleShuffle();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 40,
                  onPressed: () {
                    ref
                        .read(playbackControllerProvider.notifier)
                        .skipPrevious();
                  },
                ),
                FloatingActionButton(
                  elevation: 0,
                  onPressed: () {
                    ref
                        .read(playbackControllerProvider.notifier)
                        .togglePlayPause();
                  },
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 40,
                  onPressed: () {
                    ref.read(playbackControllerProvider.notifier).skipNext();
                  },
                ),
                IconButton(
                  icon: Icon(
                    queue.repeatMode == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                  ),
                  color: queue.repeatMode != RepeatMode.off
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  onPressed: () {
                    ref
                        .read(playbackControllerProvider.notifier)
                        .toggleRepeatMode();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
