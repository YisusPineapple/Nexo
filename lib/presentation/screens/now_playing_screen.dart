import 'dart:io';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:nexo/domain/entities/repeat_mode.dart';

import '../providers/playback_providers.dart';
import 'queue_screen.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _showLyrics = false;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Removed 'WidgetRef ref' from parameters. In ConsumerState, 'ref' is a global property.
    final queue = ref.watch(playbackControllerProvider).valueOrNull;
    final isPlaying = ref.watch(playingStreamProvider).valueOrNull ?? false;
    final position = ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;

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
          icon: const Icon(PhosphorIconsRegular.caretDown),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Now Playing',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showLyrics ? PhosphorIconsRegular.image : PhosphorIconsRegular.microphoneStage),
            tooltip: _showLyrics ? 'Show Cover' : 'Show Lyrics',
            onPressed: () {
              setState(() {
                _showLyrics = !_showLyrics;
              });
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.listDashes),
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
            // Cover Art OR Lyrics View
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showLyrics
                    ? const _LyricsView(key: ValueKey('lyrics'))
                    : _CoverArtView(
                        key: const ValueKey('cover'),
                        coverArtPath: currentSong.coverArtPath,
                      ),
              ),
            ),
            const SizedBox(height: 32),

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
                  icon: const Icon(PhosphorIconsRegular.shuffle),
                  color: queue!.shuffleEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  onPressed: () {
                    ref.read(playbackControllerProvider.notifier).toggleShuffle();
                  },
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsFill.skipBack),
                  iconSize: 36,
                  onPressed: () {
                    ref.read(playbackControllerProvider.notifier).skipPrevious();
                  },
                ),
                FloatingActionButton(
                  elevation: 0,
                  onPressed: () {
                    ref.read(playbackControllerProvider.notifier).togglePlayPause();
                  },
                  child: Icon(isPlaying ? PhosphorIconsFill.pause : PhosphorIconsFill.play, size: 32),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsFill.skipForward),
                  iconSize: 36,
                  onPressed: () {
                    ref.read(playbackControllerProvider.notifier).skipNext();
                  },
                ),
                IconButton(
                  icon: Icon(
                    queue.repeatMode == RepeatMode.one
                        ? PhosphorIconsRegular.repeatOnce
                        : PhosphorIconsRegular.repeat,
                  ),
                  color: queue.repeatMode != RepeatMode.off
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  onPressed: () {
                    ref.read(playbackControllerProvider.notifier).toggleRepeatMode();
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CoverArtView extends StatelessWidget {
  const _CoverArtView({super.key, this.coverArtPath});
  final String? coverArtPath;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: coverArtPath != null
            ? Image.file(
                File(coverArtPath!),
                fit: BoxFit.cover,
                cacheWidth: 600,
              )
            : const Icon(PhosphorIconsRegular.musicNotes, size: 100),
      ),
    );
  }
}

class _LyricsView extends StatelessWidget {
  const _LyricsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.microphoneStage, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              "Lyrics support coming soon.\n(Sub-phase 3.11)",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}