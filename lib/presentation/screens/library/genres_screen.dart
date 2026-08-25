import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/queue_source.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/alphabetical_scroll_view.dart';

class GenresScreen extends ConsumerStatefulWidget {
  const GenresScreen({super.key});

  @override
  ConsumerState<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends ConsumerState<GenresScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);
    final theme = Theme.of(context);

    return genresAsync.when(
      data: (genres) {
        if (genres.isEmpty) {
          return const Center(child: Text('No genres found.'));
        }

        final crossAxisCount = (MediaQuery.of(context).size.width / 180).floor().clamp(2, 8);
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = screenWidth - 32 - ((crossAxisCount - 1) * 16);
        final itemWidth = availableWidth / crossAxisCount;
        final itemHeight = (itemWidth / 2.0) + 16;

        return AlphabeticalScrollView(
          controller: _scrollController,
          itemCount: genres.length,
          itemExtent: itemHeight,
          crossAxisCount: crossAxisCount,
          labelBuilder: (index) => genres[index].name,
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.0,
            ),
            itemCount: genres.length,
            itemBuilder: (context, index) {
              final genre = genres[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                      theme.colorScheme.secondaryContainer.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GenreDetailScreen(genre: genre),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          genre.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${genre.songCount} songs',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                        ),
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
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.trackArtistId.value, maxLines: 1, overflow: TextOverflow.ellipsis),
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
