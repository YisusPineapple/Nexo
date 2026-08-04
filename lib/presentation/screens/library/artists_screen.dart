import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/queue_source.dart';
import '../../../domain/value_objects/artist_id.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';

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
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: artist.coverArtPath != null
                    ? FileImage(File(artist.coverArtPath!))
                    : null,
                child: artist.coverArtPath == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(artist.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${artist.albumCount} albums • ${artist.songCount} songs'),
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

class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final ArtistUiModel artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(artistSongsProvider(artist.name));

    return Scaffold(
      appBar: AppBar(title: Text(artist.name)),
      body: songsAsync.when(
        data: (songs) {
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: song.coverArtPath != null
                      ? Image.file(File(song.coverArtPath!),
                          width: 48, height: 48, fit: BoxFit.cover)
                      : Container(
                          width: 48,
                          height: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.music_note),
                        ),
                ),
                title: Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.albumId?.value ?? 'Unknown Album',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  ref.read(playbackControllerProvider.notifier).playSongs(
                        queueIdStr: 'artist_${artist.name}',
                        songs: songs,
                        startIndex: index,
                        source: ArtistQueueSource(
                          artistId: ArtistId(artist.name),
                          artistName: artist.name,
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
