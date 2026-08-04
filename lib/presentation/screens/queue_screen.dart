import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/playback_providers.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playbackControllerProvider).valueOrNull;

    if (queue == null || queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playback Queue')),
        body: const Center(child: Text('The queue is empty.')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Playback Queue'),
            Text(
              '${queue.songs.length} songs',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: ReorderableListView.builder(
        itemCount: queue.songs.length,
        onReorderItem: (int oldIndex, int newIndex) {
          ref.read(playbackControllerProvider.notifier).reorderQueue(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final song = queue.songs[index];
          final isCurrent = index == queue.currentIndex;

          return ListTile(
            // Key must be unique even if the same song appears twice in the queue.
            key: ValueKey('${song.id.value}_$index'),
            selected: isCurrent,
            selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: song.coverArtPath != null
                  ? Image.file(
                      File(song.coverArtPath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.music_note),
                    ),
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? theme.colorScheme.primary : null,
              ),
            ),
            subtitle: Text(
              song.trackArtistId.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            onTap: () {
              ref.read(playbackControllerProvider.notifier).skipToIndex(index);
            },
          );
        },
      ),
    );
  }
}