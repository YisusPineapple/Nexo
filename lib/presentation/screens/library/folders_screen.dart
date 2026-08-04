import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/queue_source.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      data: (folders) {
        if (folders.isEmpty) {
          return const Center(child: Text('No folders found.'));
        }

        return ListView.builder(
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(folder.path,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text('${folder.songCount}'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FolderDetailScreen(folder: folder),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({super.key, required this.folder});

  final FolderUiModel folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(folderSongsProvider(folder.path));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folder.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              folder.path,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      body: songsAsync.when(
        data: (songs) {
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: const Icon(Icons.audio_file),
                title: Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.trackArtistId.value,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  ref.read(playbackControllerProvider.notifier).playSongs(
                        queueIdStr: 'folder_${folder.path}',
                        songs: songs,
                        startIndex: index,
                        source: FolderQueueSource(
                          folderPath: folder.path,
                          folderName: folder.name,
                        ),
                      );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
