import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../providers/playback_providers.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(playbackControllerProvider);
    final isPlaying = ref.watch(playingStreamProvider).valueOrNull ?? false;
    final position = ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;
    
    final queue = queueAsync.valueOrNull;
    final currentSong = queue?.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final duration = currentSong.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    final theme = Theme.of(context);
    double dragDistanceX = 0;

    // FIX: Wrapped in Dismissible for native, fluid swipe-down-to-close behavior
    return Dismissible(
      key: const Key('nexo_miniplayer'),
      direction: DismissDirection.down,
      onDismissed: (_) {
        ref.read(playbackControllerProvider.notifier).stop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playback stopped'), duration: Duration(milliseconds: 800)),
        );
      },
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => const NowPlayingScreen(),
          );
        },
        // Horizontal drag for next/previous (using distance, not velocity, for mouse support)
        onHorizontalDragStart: (_) => dragDistanceX = 0,
        onHorizontalDragUpdate: (details) => dragDistanceX += details.delta.dx,
        onHorizontalDragEnd: (_) {
          if (dragDistanceX > 40) {
            ref.read(playbackControllerProvider.notifier).skipPrevious();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Previous track'), duration: Duration(milliseconds: 800)),
            );
          } else if (dragDistanceX < -40) {
            ref.read(playbackControllerProvider.notifier).skipNext();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Next track'), duration: Duration(milliseconds: 800)),
            );
          }
        },
        child: Container(
          height: 68,
          margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  color: theme.colorScheme.primary,
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 8),
                  if (currentSong.coverArtPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(currentSong.coverArtPath!),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        cacheWidth: 150,
                      ),
                    )
                  else
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(PhosphorIconsRegular.musicNotes, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                        ),
                        Text(
                          currentSong.trackArtistId.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(isPlaying ? PhosphorIconsFill.pause : PhosphorIconsFill.play),
                    color: theme.colorScheme.onSecondaryContainer,
                    onPressed: () {
                      ref.read(playbackControllerProvider.notifier).togglePlayPause();
                    },
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsFill.skipForward),
                    color: theme.colorScheme.onSecondaryContainer,
                    onPressed: () {
                      ref.read(playbackControllerProvider.notifier).skipNext();
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}