import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/queue_source.dart';
import '../../../domain/entities/song_sort_option.dart';
import '../../providers/library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/alphabetical_scroll_view.dart';
import '../../widgets/song_context_menu.dart';

const double _songRowExtent = 72;

extension _SongSortOptionLabel on SongSortOption {
  String get label {
    switch (this) {
      case SongSortOption.title:
        return 'Title';
      case SongSortOption.artist:
        return 'Artist';
      case SongSortOption.album:
        return 'Album';
      case SongSortOption.year:
        return 'Year';
      case SongSortOption.duration:
        return 'Duration';
      case SongSortOption.dateAdded:
        return 'Date added';
    }
  }
}

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
    final query = ref.watch(songSearchQueryProvider);
    final sortConfig = ref.watch(songSortProvider);
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
                  IconButton(
                    icon: Icon(sortConfig.isAscending
                        ? PhosphorIconsRegular.sortAscending
                        : PhosphorIconsRegular.sortDescending),
                    tooltip: 'Toggle Order',
                    onPressed: () {
                      ref.read(songSortProvider.notifier).state = sortConfig
                          .copyWith(isAscending: !sortConfig.isAscending);
                    },
                  ),
                  PopupMenuButton<SongSortOption>(
                    initialValue: sortConfig.option,
                    tooltip: 'Sort by',
                    icon: const Icon(PhosphorIconsRegular.arrowsDownUp),
                    onSelected: (option) => ref
                        .read(songSortProvider.notifier)
                        .state = sortConfig.copyWith(option: option),
                    itemBuilder: (context) => [
                      for (final option in SongSortOption.values)
                        PopupMenuItem(value: option, child: Text(option.label)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: query.isNotEmpty
                  ? _SearchResultsView(scrollController: _scrollController)
                  : _VirtualPaginationView(scrollController: _scrollController),
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtualPaginationView extends ConsumerWidget {
  const _VirtualPaginationView({required this.scrollController});
  final ScrollController scrollController;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexAsync = ref.watch(alphabeticalIndexProvider);
    final windowState = ref.watch(songsWindowProvider);
    final theme = Theme.of(context);
    final cacheSize = (150 * MediaQuery.devicePixelRatioOf(context)).round();

    return indexAsync.when(
      data: (sectionIndex) {
        if (windowState.totalCount == 0) {
          return const Center(
            child: Text('No songs found. Go to Library to add a folder.'),
          );
        }

        final list = CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverFixedExtentList(
              itemExtent: _songRowExtent,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  Future.microtask(() => ref
                      .read(songsWindowProvider.notifier)
                      .ensureLoaded(index));

                  final song = ref
                      .read(songsWindowProvider.notifier)
                      .getSongAtIndex(index);

                  if (song == null) {
                    return const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading...'),
                    );
                  }

                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: song.coverArtPath != null
                          ? Image.file(
                              File(song.coverArtPath!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              cacheWidth: cacheSize,
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child:
                                  const Icon(PhosphorIconsRegular.musicNotes),
                            ),
                    ),
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
                          backgroundColor: Colors.transparent,
                          builder: (context) => SongContextMenu(song: song),
                        );
                      },
                    ),
                    onTap: () async {
                      final allSongs =
                          await ref.read(sortedSongsProvider.future);
                      if (context.mounted) {
                        unawaited(ref
                            .read(playbackControllerProvider.notifier)
                            .playSongs(
                              queueIdStr: 'library_songs',
                              songs: allSongs,
                              startIndex: index,
                              source: const ManualQueueSource(),
                            ));
                      }
                    },
                  );
                },
                childCount: windowState.totalCount,
              ),
            ),
          ],
        );

        return AlphabeticalScrollView(
          controller: scrollController,
          itemExtent: _songRowExtent,
          sectionIndex: sectionIndex,
          child: list,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({required this.scrollController});
  final ScrollController scrollController;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(sortedSongsProvider);
    final theme = Theme.of(context);
    final cacheSize = (150 * MediaQuery.devicePixelRatioOf(context)).round();

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView.builder(
          controller: scrollController,
          itemExtent: _songRowExtent,
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: song.coverArtPath != null
                    ? Image.file(
                        File(song.coverArtPath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        cacheWidth: cacheSize,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(PhosphorIconsRegular.musicNotes),
                      ),
              ),
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
                    backgroundColor: Colors.transparent,
                    builder: (context) => SongContextMenu(song: song),
                  );
                },
              ),
              onTap: () {
                ref.read(playbackControllerProvider.notifier).playSongs(
                      queueIdStr: 'search_results',
                      songs: songs,
                      startIndex: index,
                      source: const ManualQueueSource(),
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
