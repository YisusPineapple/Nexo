import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/queue_source.dart';
import '../../providers/library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../utils/song_sort.dart';
import '../../widgets/alphabetical_scroll_view.dart';
import '../../widgets/song_context_menu.dart';

const double _songRowExtent = 72;

class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(songSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(sortedSongsProvider);
    final sortOption = ref.watch(songSortOptionProvider);
    final theme = Theme.of(context);

    final isAlphabeticalSort = sortOption == SongSortOption.title ||
        sortOption == SongSortOption.artist;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onQueryChanged,
                      decoration: InputDecoration(
                        hintText: 'Search songs, artists, albums',
                        prefixIcon:
                            const Icon(PhosphorIconsRegular.magnifyingGlass),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<SongSortOption>(
                    initialValue: sortOption,
                    tooltip: 'Sort by',
                    icon: const Icon(PhosphorIconsRegular.arrowsDownUp),
                    onSelected: (option) => ref
                        .read(songSortOptionProvider.notifier)
                        .state = option,
                    itemBuilder: (context) => [
                      for (final option in SongSortOption.values)
                        PopupMenuItem(value: option, child: Text(option.label)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: songsAsync.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return const Center(
                      child: Text(
                          'No songs found. Go to Library to add a folder.'),
                    );
                  }

                  final list = ListView.builder(
                    controller: _scrollController,
                    itemExtent: _songRowExtent,
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${song.trackArtistId.value} • '
                          '${_formatDuration(song.duration)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              // FIX: Set to transparent so the floating card design works
                              backgroundColor: Colors.transparent,
                              builder: (context) => SongContextMenu(song: song),
                            );
                          },
                        ),
                        onTap: () {
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playSongs(
                                queueIdStr: 'library_songs',
                                songs: songs,
                                startIndex: index,
                                source: const ManualQueueSource(),
                              );
                        },
                      );
                    },
                  );

                  if (!isAlphabeticalSort) {
                    return Scrollbar(
                      controller: _scrollController,
                      interactive: true,
                      thickness: 8,
                      radius: const Radius.circular(4),
                      child: list,
                    );
                  }

                  return AlphabeticalScrollView(
                    controller: _scrollController,
                    itemCount: songs.length,
                    itemExtent: _songRowExtent,
                    version: sortOption,
                    labelBuilder: (index) => sortOption == SongSortOption.title
                        ? songs[index].title
                        : songs[index].trackArtistId.value,
                    child: list,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}