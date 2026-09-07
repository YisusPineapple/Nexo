import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/utils/artist_splitter.dart';
import '../../../domain/entities/library_aggregates.dart';
import '../../../domain/entities/queue_source.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/value_objects/artist_id.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/alphabetical_scroll_view.dart';
import '../../widgets/soft_card.dart';

const double _artistRowExtent = 92.0;

class ArtistsScreen extends ConsumerStatefulWidget {
  const ArtistsScreen({super.key});

  @override
  ConsumerState<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends ConsumerState<ArtistsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(artistsProvider);
    final sortConfig = ref.watch(artistSortProvider);
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
                    'Artists',
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
                      ref.read(artistSortProvider.notifier).state = sortConfig
                          .copyWith(isAscending: !sortConfig.isAscending);
                    },
                  ),
                  PopupMenuButton<ArtistSortOption>(
                    initialValue: sortConfig.option,
                    tooltip: 'Sort by',
                    icon: const Icon(PhosphorIconsRegular.arrowsDownUp),
                    onSelected: (option) => ref
                        .read(artistSortProvider.notifier)
                        .state = sortConfig.copyWith(option: option),
                    itemBuilder: (context) => [
                      for (final option in ArtistSortOption.values)
                        PopupMenuItem(
                            value: option,
                            child: Text('Sort by ${option.name}')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: artistsAsync.when(
                data: (artists) {
                  if (artists.isEmpty) {
                    return const Center(child: Text('No artists found.'));
                  }

                  final list = ListView.builder(
                    controller: _scrollController,
                    itemExtent: _artistRowExtent,
                    itemCount: artists.length,
                    itemBuilder: (context, index) {
                      final artist = artists[index];
                      return SoftCard(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ArtistDetailScreen(artist: artist))),
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            _ArtistAvatar(
                                name: artist.name,
                                coverArtPath: artist.coverArtPath),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(artist.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('${artist.songCount} songs',
                                          style: theme.textTheme.bodySmall),
                                      if (artist.albumCount > 0) ...[
                                        Text(' • ',
                                            style: theme.textTheme.bodySmall),
                                        Text('${artist.albumCount} albums',
                                            style: theme.textTheme.bodySmall)
                                      ],
                                      if (artist.collaborationCount > 0) ...[
                                        Text(' • ',
                                            style: theme.textTheme.bodySmall),
                                        Text(
                                            '${artist.collaborationCount} collabs',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: theme
                                                        .colorScheme.primary))
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(PhosphorIconsRegular.caretRight,
                                size: 16),
                          ],
                        ),
                      );
                    },
                  );

                  return AlphabeticalScrollView(
                    controller: _scrollController,
                    itemCount: artists.length,
                    itemExtent: _artistRowExtent,
                    version: sortConfig,
                    labelBuilder: (index) {
                      final artist = artists[index];
                      return switch (sortConfig.option) {
                        ArtistSortOption.name => artist.name,
                        ArtistSortOption.songCount => '${artist.songCount}',
                        ArtistSortOption.albumCount => '${artist.albumCount}',
                      };
                    },
                    child: list,
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

class _ArtistAvatar extends StatelessWidget {
  const _ArtistAvatar({required this.name, this.coverArtPath});
  final String name;
  final String? coverArtPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 28,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: coverArtPath != null
          ? ResizeImage(FileImage(File(coverArtPath!)), width: 150)
              as ImageProvider
          : null,
      child: coverArtPath == null
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer))
          : null,
    );
  }
}

class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artist});
  final Artist artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(multiArtistSongsProvider(artist.name));
    final theme = Theme.of(context);

    return Scaffold(
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('No songs found.'));
          }
          final normalizedTarget = normalizeArtist(artist.name);
          final mainSongs = <Song>[];
          final collabSongs = <Song>[];

          for (final song in songs) {
            final artists = splitArtists(song.trackArtistId.value);
            final isTargetArtist = artists
                .any((name) => normalizeArtist(name) == normalizedTarget);
            if (artists.length == 1 || isTargetArtist) {
              mainSongs.add(song);
            } else {
              collabSongs.add(song);
            }
          }

          return Scrollbar(
            interactive: true,
            thickness: 8,
            radius: const Radius.circular(4),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  stretch: true,
                  backgroundColor: theme.colorScheme.surface,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    title: Text(
                      artist.name,
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
                        if (artist.coverArtPath != null)
                          Image.file(
                            File(artist.coverArtPath!),
                            fit: BoxFit.cover,
                            cacheWidth: 600,
                          )
                        else
                          Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              PhosphorIconsRegular.user,
                              size: 100,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                theme.colorScheme.surface
                                    .withValues(alpha: 0.2),
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${artist.songCount} songs • ${artist.albumCount} albums • ${artist.collaborationCount} collabs',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => ref
                                    .read(playbackControllerProvider.notifier)
                                    .playSongs(
                                        queueIdStr: 'artist_${artist.name}',
                                        songs: songs,
                                        startIndex: 0,
                                        source: ArtistQueueSource(
                                            artistId: ArtistId(artist.name),
                                            artistName: artist.name)),
                                icon: const Icon(PhosphorIconsFill.play),
                                label: const Text('Play All'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () async {
                                final error = await ref
                                    .read(playbackControllerProvider.notifier)
                                    .playSongs(
                                      queueIdStr:
                                          'artist_${artist.name}_${DateTime.now().millisecondsSinceEpoch}',
                                      songs: songs,
                                      startIndex: 0,
                                      source: ArtistQueueSource(
                                          artistId: ArtistId(artist.name),
                                          artistName: artist.name),
                                      openAsNewTab: true,
                                    );
                                if (error != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error)));
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Opened in new tab')));
                                }
                              },
                              icon: const Icon(PhosphorIconsRegular.plusSquare),
                              tooltip: 'Play in new tab',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (mainSongs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text('As main artist',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary)))),
                  SliverList(
                      delegate: SliverChildBuilderDelegate(
                          (context, index) => _SongTile(
                              song: mainSongs[index],
                              onTap: () => ref
                                  .read(playbackControllerProvider.notifier)
                                  .playSongs(
                                      queueIdStr: 'artist_main_${artist.name}',
                                      songs: mainSongs,
                                      startIndex: index,
                                      source: ArtistQueueSource(
                                          artistId: ArtistId(artist.name),
                                          artistName: artist.name))),
                          childCount: mainSongs.length)),
                ],
                if (collabSongs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text('Collaborations',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary)))),
                  SliverList(
                      delegate: SliverChildBuilderDelegate(
                          (context, index) => _SongTile(
                              song: collabSongs[index],
                              onTap: () => ref
                                  .read(playbackControllerProvider.notifier)
                                  .playSongs(
                                      queueIdStr:
                                          'artist_collab_${artist.name}',
                                      songs: collabSongs,
                                      startIndex: index,
                                      source: ArtistQueueSource(
                                          artistId: ArtistId(artist.name),
                                          artistName: artist.name))),
                          childCount: collabSongs.length)),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({required this.song, required this.onTap});
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: song.coverArtPath != null
            ? Image.file(File(song.coverArtPath!),
                width: 48, height: 48, fit: BoxFit.cover, cacheWidth: 96)
            : Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(PhosphorIconsRegular.musicNotes, size: 20)),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.trackArtistId.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      onTap: onTap,
    );
  }
}
