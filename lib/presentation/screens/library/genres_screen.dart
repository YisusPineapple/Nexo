import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/queue_source.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';

class GenresScreen extends ConsumerWidget {
  const GenresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);

    return genresAsync.when(
      data: (genres) {
        if (genres.isEmpty) {
          return const Center(child: Text('No genres found.'));
        }

        final crossAxisCount =
            (MediaQuery.of(context).size.width / 180).floor().clamp(2, 8);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.0, // Wide cards
          ),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            final genre = genres[index];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GenreDetailScreen(genre: genre),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      genre.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${genre.songCount} songs',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                    ),
                  ],
                ),
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

class GenreDetailScreen extends ConsumerWidget {
  const GenreDetailScreen({super.key, required this.genre});

  final GenreUiModel genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(genreSongsProvider(genre.name));

    return Scaffold(
      appBar: AppBar(title: Text(genre.name)),
      body: songsAsync.when(
        data: (songs) {
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                title: Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.trackArtistId.value,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  ref.read(playbackControllerProvider.notifier).playSongs(
                        queueIdStr: 'genre_${genre.name}',
                        songs: songs,
                        startIndex: index,
                        source: GenreQueueSource(genreName: genre.name),
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
