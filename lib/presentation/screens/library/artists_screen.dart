import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/queue_source.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/value_objects/artist_id.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../utils/artist_splitter.dart';

class ArtistsScreen extends ConsumerWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);
    final sortOption = ref.watch(artistSortOptionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ArtistSortOption.values.map((option) {
                  return ListTile(
                    title: Text('Sort by ${option.name}'),
                    trailing: sortOption == option
                        ? const Icon(PhosphorIconsRegular.check)
                        : null,
                    onTap: () {
                      ref.read(artistSortOptionProvider.notifier).state =
                          option;
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
        child: const Icon(PhosphorIconsRegular.arrowsDownUp),
      ),
      body: artistsAsync.when(
        data: (artists) {
          if (artists.isEmpty) {
            return const Center(child: Text('No artists found.'));
          }
          return Scrollbar(
            interactive: true,
            thickness: 8,
            radius: const Radius.circular(4),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(artist: artist))),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          _ArtistAvatar(
                              name: artist.name, coverArtPath: artist.coverArtPath),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(artist.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('${artist.songCount} songs', style: theme.textTheme.bodySmall),
                                    if (artist.albumCount > 0) ...[
                                      Text(' • ', style: theme.textTheme.bodySmall),
                                      Text('${artist.albumCount} albums', style: theme.textTheme.bodySmall)
                                    ],
                                    if (artist.collaborationCount > 0) ...[
                                      Text(' • ', style: theme.textTheme.bodySmall),
                                      Text('${artist.collaborationCount} collabs',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.primary))
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(PhosphorIconsRegular.caretRight, size: 16),
                        ],
                      ),
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
          ? ResizeImage(FileImage(File(coverArtPath!)), width: 112)
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
  final ArtistUiModel artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(multiArtistSongsProvider(artist.name));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
        leading: const BackButton(),
      ),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ArtistAvatar(
                                name: artist.name,
                                coverArtPath: artist.coverArtPath),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(artist.name,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${artist.songCount} songs • ${artist.albumCount} albums • ${artist.collaborationCount} collabs',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
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