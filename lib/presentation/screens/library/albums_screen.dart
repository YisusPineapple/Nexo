import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/queue_source.dart';
import '../../../domain/value_objects/album_id.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/alphabetical_scroll_view.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumsProvider);
    final sortConfig = ref.watch(albumSortProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    'Albums',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(sortConfig.isAscending
                        ? PhosphorIconsRegular.sortAscending
                        : PhosphorIconsRegular.sortDescending),
                    tooltip: 'Toggle Order',
                    onPressed: () {
                      ref.read(albumSortProvider.notifier).state =
                          sortConfig.copyWith(isAscending: !sortConfig.isAscending);
                    },
                  ),
                  PopupMenuButton<AlbumSortOption>(
                    initialValue: sortConfig.option,
                    tooltip: 'Sort by',
                    icon: const Icon(PhosphorIconsRegular.arrowsDownUp),
                    onSelected: (option) => ref
                        .read(albumSortProvider.notifier)
                        .state = sortConfig.copyWith(option: option),
                    itemBuilder: (context) => [
                      for (final option in AlbumSortOption.values)
                        PopupMenuItem(value: option, child: Text('Sort by ${option.name}')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: albumsAsync.when(
                data: (albums) {
                  if (albums.isEmpty) return const Center(child: Text('No albums found.'));
                  
                  final crossAxisCount = (MediaQuery.of(context).size.width / 160).floor().clamp(2, 10);
                  final screenWidth = MediaQuery.of(context).size.width;
                  final availableWidth = screenWidth - 32 - ((crossAxisCount - 1) * 16);
                  final itemWidth = availableWidth / crossAxisCount;
                  final itemHeight = (itemWidth / 0.75) + 16;

                  return AlphabeticalScrollView(
                    controller: _scrollController,
                    itemCount: albums.length,
                    itemExtent: itemHeight,
                    crossAxisCount: crossAxisCount,
                    version: sortConfig,
                    labelBuilder: (index) {
                      final album = albums[index];
                      return switch (sortConfig.option) {
                        AlbumSortOption.name => album.name,
                        AlbumSortOption.artist => album.artist,
                        AlbumSortOption.songCount => '${album.songCount}',
                      };
                    },
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: album.coverArtPath != null
                                        ? Image.file(File(album.coverArtPath!), fit: BoxFit.cover, cacheWidth: 400)
                                        : const Icon(Icons.album, size: 48),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        album.name, 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis, 
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        album.artist, 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis, 
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
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
          return Scrollbar(
            interactive: true,
            thickness: 8,
            radius: const Radius.circular(4),
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: Text(song.trackNumber?.toString() ?? '-', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.trackArtistId.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => ref.read(playbackControllerProvider.notifier).playSongs(queueIdStr: 'album_${album.id}', songs: songs, startIndex: index, source: AlbumQueueSource(albumId: AlbumId(album.id), albumName: album.name)),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
