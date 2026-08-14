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
    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) {
          return const Center(child: Text('No artists found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: _ArtistAvatar(
                name: artist.name,
                coverArtPath: artist.coverArtPath,
              ),
              title: Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Row(
                children: [
                  Text('${artist.songCount} songs'),
                  if (artist.albumCount > 0) ...[
                    const Text(' • '),
                    Text('${artist.albumCount} albums'),
                  ],
                  if (artist.collaborationCount > 0) ...[
                    const Text(' • '),
                    Text(
                      '${artist.collaborationCount} collabs',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ArtistDetailScreen(artist: artist),
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

/// Circular avatar showing either the artist's cover art or their
/// first initial as a fallback. Gives the Artists list a premium,
/// Spotify-like visual rhythm without requiring every artist to have
/// embedded art.
class _ArtistAvatar extends StatelessWidget {
  const _ArtistAvatar({required this.name, this.coverArtPath});

  final String name;
  final String? coverArtPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: coverArtPath != null
          ? ResizeImage(FileImage(File(coverArtPath!)), width: 96)
              as ImageProvider
          : null,
      child: coverArtPath == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}

class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artist});
  final ArtistUiModel artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uses multiArtistSongsProvider so collaborations are included.
    final songsAsync = ref.watch(multiArtistSongsProvider(artist.name));
    final theme = Theme.of(context);

    return Scaffold(
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('No songs found.'));
          }

          // Partition songs into "main artist" vs "collaborations"
          // for a richer UX (user sees both roles clearly).
          // We use the centralized normalizeArtist to ensure exact matching
          // regardless of trailing spaces or casing.
          final normalizedTarget = normalizeArtist(artist.name);
          final mainSongs = <Song>[];
          final collabSongs = <Song>[];

          for (final song in songs) {
            final artists = splitArtists(song.trackArtistId.value);
            final isTargetArtist = artists.any(
              (name) => normalizeArtist(name) == normalizedTarget,
            );

            if (artists.length == 1 || isTargetArtist) {
              mainSongs.add(song);
            } else {
              collabSongs.add(song);
            }
          }

          return CustomScrollView(
            slivers: [
              // Hero-style header with artist info
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
                            coverArtPath: artist.coverArtPath,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artist.name,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${artist.songCount} songs • '
                                  '${artist.albumCount} albums • '
                                  '${artist.collaborationCount} collabs',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Play all button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .playSongs(
                                  queueIdStr: 'artist_${artist.name}',
                                  songs: songs,
                                  startIndex: 0,
                                  source: ArtistQueueSource(
                                    artistId: ArtistId(artist.name),
                                    artistName: artist.name,
                                  ),
                                );
                          },
                          icon: const Icon(PhosphorIconsFill.play),
                          label: const Text('Play All'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section: As main artist
              if (mainSongs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'As main artist',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = mainSongs[index];
                      return _SongTile(
                        song: song,
                        onTap: () {
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playSongs(
                                queueIdStr: 'artist_main_${artist.name}',
                                songs: mainSongs,
                                startIndex: index,
                                source: ArtistQueueSource(
                                  artistId: ArtistId(artist.name),
                                  artistName: artist.name,
                                ),
                              );
                        },
                      );
                    },
                    childCount: mainSongs.length,
                  ),
                ),
              ],

              // Section: Collaborations
              if (collabSongs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Collaborations',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = collabSongs[index];
                      return _SongTile(
                        song: song,
                        onTap: () {
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playSongs(
                                queueIdStr: 'artist_collab_${artist.name}',
                                songs: collabSongs,
                                startIndex: index,
                                source: ArtistQueueSource(
                                  artistId: ArtistId(artist.name),
                                  artistName: artist.name,
                                ),
                              );
                        },
                      );
                    },
                    childCount: collabSongs.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator())),
        error: (e, st) => SliverFillRemaining(
          child: Center(child: Text('Error: $e')),
        ),
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
            ? Image.file(
                File(song.coverArtPath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                cacheWidth: 96,
              )
            : Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(PhosphorIconsRegular.musicNotes, size: 20),
              ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.trackArtistId.value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}