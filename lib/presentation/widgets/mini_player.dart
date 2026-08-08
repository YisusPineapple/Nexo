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

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => const NowPlayingScreen(),
        );
      },
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  if (currentSong.coverArtPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(currentSong.coverArtPath!),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        cacheWidth: 150,
                      ),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(PhosphorIconsRegular.musicNotes),
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          currentSong.trackArtistId.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(isPlaying ? PhosphorIconsFill.pause : PhosphorIconsFill.play),
                    onPressed: () {
                      ref.read(playbackControllerProvider.notifier).togglePlayPause();
                    },
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsFill.skipForward),
                    onPressed: () {
                      ref.read(playbackControllerProvider.notifier).skipNext();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}