import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/queue_source.dart';
import '../../../domain/value_objects/album_id.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return const Center(child: Text('No albums found.'));
        }

        // Adaptive grid: 160dp minimum width per item
        final crossAxisCount =
            (MediaQuery.of(context).size.width / 160).floor().clamp(2, 10);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, // Taller to fit text below cover
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlbumDetailScreen(album: album),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: album.coverArtPath != null
                            ? Image.file(File(album.coverArtPath!),
                                fit: BoxFit.cover)
                            : const Icon(Icons.album, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    album.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final AlbumUiModel album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(albumSongsProvider(album.id));

    return Scaffold(
      appBar: AppBar(title: Text(album.name)),
      body: songsAsync.when(
        data: (songs) {
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: Text(
                  song.trackNumber?.toString() ?? '-',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                title: Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.trackArtistId.value,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  ref.read(playbackControllerProvider.notifier).playSongs(
                        queueIdStr: 'album_${album.id}',
                        songs: songs,
                        startIndex: index,
                        source: AlbumQueueSource(
                          albumId: AlbumId(album.id),
                          albumName: album.name,
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
