import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../providers/playback_providers.dart';
import '../screens/now_playing_screen.dart';
import 'marquee_text.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({
    super.key,
    this.onTap,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final VoidCallback? onTap;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

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

    // FIX: Removed Dismissible. It was conflicting with the vertical drag gesture.
    return GestureDetector(
      onTap: onTap ?? () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: theme.colorScheme.surface,
          builder: (context) => const NowPlayingScreen(),
        );
      },
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd ?? (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: theme.colorScheme.surface,
            builder: (context) => const NowPlayingScreen(),
          );
        }
      },
      onHorizontalDragStart: (_) => dragDistanceX = 0,
      onHorizontalDragUpdate: (details) => dragDistanceX += details.delta.dx,
      onHorizontalDragEnd: (_) {
        if (dragDistanceX > 40) {
          ref.read(playbackControllerProvider.notifier).skipPrevious();
        } else if (dragDistanceX < -40) {
          ref.read(playbackControllerProvider.notifier).skipNext();
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
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 12,
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
                Hero(
                  tag: 'cover_${currentSong.id.value}',
                  child: currentSong.coverArtPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(currentSong.coverArtPath!),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            cacheWidth: 150,
                          ),
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(PhosphorIconsRegular.musicNotes, color: theme.colorScheme.onSurfaceVariant),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MarqueeText(
                        text: currentSong.title,
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: IconButton(
                    key: ValueKey(isPlaying),
                    icon: Icon(isPlaying ? PhosphorIconsFill.pause : PhosphorIconsFill.play),
                    color: theme.colorScheme.onSecondaryContainer,
                    onPressed: () {
                      ref.read(playbackControllerProvider.notifier).togglePlayPause();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsFill.skipForward),
                  color: theme.colorScheme.onSecondaryContainer,
                  onPressed: () {
                    ref.read(playbackControllerProvider.notifier).skipNext();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => ref.read(playbackControllerProvider.notifier).stop(),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      PhosphorIconsRegular.x,
                      size: 14,
                      color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}