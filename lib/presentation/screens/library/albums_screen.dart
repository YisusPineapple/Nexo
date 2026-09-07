import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/library_aggregates.dart';
import '../../../domain/entities/queue_source.dart';
import '../../../domain/value_objects/album_id.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/alphabetical_scroll_view.dart';
import '../../widgets/soft_card.dart';

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      ref.read(albumSortProvider.notifier).state = sortConfig
                          .copyWith(isAscending: !sortConfig.isAscending);
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
                        PopupMenuItem(
                            value: option,
                            child: Text('Sort by ${option.name}')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: albumsAsync.when(
                data: (albums) {
                  if (albums.isEmpty) {
                    return const Center(child: Text('No albums found.'));
                  }

                  final crossAxisCount =
                      (MediaQuery.of(context).size.width / 160)
                          .floor()
                          .clamp(2, 10);
                  final screenWidth = MediaQuery.of(context).size.width;
                  final availableWidth =
                      screenWidth - 32 - ((crossAxisCount - 1) * 16);
                  final itemWidth = availableWidth / crossAxisCount;

                  final itemHeight = (itemWidth / 0.65) + 16;

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
                        childAspectRatio: 0.65,
                      ),
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return SoftCard(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AlbumDetailScreen(album: album))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: album.coverArtPath != null
                                      ? Image.file(File(album.coverArtPath!),
                                          fit: BoxFit.cover, cacheWidth: 300)
                                      : const Icon(PhosphorIconsRegular.disc,
                                          size: 48),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(album.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(album.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
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
  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(albumSongsProvider(album.id));
    final theme = Theme.of(context);

    return Scaffold(
      body: songsAsync.when(
        data: (songs) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  title: Text(
                    album.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      shadows: [
                        Shadow(
                          color: theme.colorScheme.surface,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (album.coverArtPath != null)
                        Image.file(
                          File(album.coverArtPath!),
                          fit: BoxFit.cover,
                          cacheWidth: 600,
                        )
                      else
                        Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            PhosphorIconsRegular.disc,
                            size: 100,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      // Gradient overlay to ensure text is readable and blends into the list
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.colorScheme.surface.withValues(alpha: 0.2),
                              theme.colorScheme.surface,
                            ],
                            stops: const [0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.artist,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${album.songCount} songs',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          if (songs.isNotEmpty) {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .playSongs(
                                  queueIdStr: 'album_${album.id}',
                                  songs: songs,
                                  startIndex: 0,
                                  source: AlbumQueueSource(
                                      albumId: AlbumId(album.id),
                                      albumName: album.name),
                                );
                          }
                        },
                        elevation: 0,
                        child: const Icon(PhosphorIconsFill.play),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: SizedBox(
                        width: 32,
                        child: Center(
                          child: Text(
                            song.trackNumber?.toString() ?? '-',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(song.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.trackArtistId.value,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => ref
                          .read(playbackControllerProvider.notifier)
                          .playSongs(
                            queueIdStr: 'album_${album.id}',
                            songs: songs,
                            startIndex: index,
                            source: AlbumQueueSource(
                                albumId: AlbumId(album.id),
                                albumName: album.name),
                          ),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
