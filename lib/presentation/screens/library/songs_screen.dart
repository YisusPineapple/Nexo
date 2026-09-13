import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/queue_source.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/song_sort_option.dart';
import '../../providers/library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/songs_window_provider.dart';
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Loads the full sorted+filtered list for playback queue construction.
  /// The playback engine needs the entire queue, not just the visible
  /// window; this is a one-shot read, independent of the paginated
  /// [SongsWindowState] used for rendering.
  ///
  /// Reads the repository directly, matching how
  /// `grouped_library_providers.dart` already consumes
  /// `watchSongsByAlbum/Artist/Folder`. Uses `Result.valueOrNull` rather
  /// than throwing — a failure degrades gracefully to a one-song queue
  /// instead of surfacing an exception to the UI.
  Future<void> _playFromRow(Song song) async {
    final repo = ref.read(songRepositoryProvider);
    final sort = ref.read(songSortProvider);
    final query = ref.read(songSearchQueryProvider);

    final result = query.isEmpty
        ? await repo.getAllSongs(
            sortOption: sort.option,
            isAscending: sort.isAscending,
          )
        : await repo.searchSongs(
            query,
            sortOption: sort.option,
            isAscending: sort.isAscending,
          );

    if (!mounted) return;

    final fullList = result.valueOrNull ?? <Song>[song];
    final indexInFull = fullList.indexWhere((s) => s.id == song.id);

    final error = await ref.read(playbackControllerProvider.notifier).playSongs(
          queueIdStr: 'library_songs',
          songs: fullList,
          startIndex: indexInFull < 0 ? 0 : indexInFull,
          source: const ManualQueueSource(),
        );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  void _showContextMenu(Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongContextMenu(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(songsWindowProvider);
    final sortConfig = ref.watch(songSortProvider);
    final sectionsAsync = ref.watch(songsAlphabeticalIndexProvider);
    final sections = sectionsAsync.valueOrNull ?? const <(String, int)>[];
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
            Expanded(child: _buildBody(state, sections)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    SongsWindowState state,
    List<(String, int)> sections,
  ) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.initialError != null) {
      return _ErrorState(
        message: state.initialError!.message,
        onRetry: () =>
            ref.read(songsWindowProvider.notifier).retryInitialLoad(),
      );
    }

    if (state.totalCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No songs found. Go to Library to add a folder.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final list = ListView.builder(
      controller: _scrollController,
      itemExtent: _songRowExtent,
      itemCount: state.totalCount,
      itemBuilder: (context, index) {
        final song = state.songAt(index);
        if (song == null) {
          // Placeholder row: its page is not in the LRU yet. Schedule
          // the load AFTER the current frame — calling `loadPage`
          // synchronously from `itemBuilder` mutates provider state
          // mid-build, which Riverpod forbids.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref
                .read(songsWindowProvider.notifier)
                .loadPage(index ~/ kSongsWindowPageSize);
          });
          return const _SongRowPlaceholder();
        }

        return _SongRow(
          song: song,
          durationLabel: _formatDuration(song.duration),
          onTap: () => _playFromRow(song),
          onShowMenu: () => _showContextMenu(song),
        );
      },
    );

    // AlphabeticalScrollView in SQL mode: `sectionIndex` is non-null,
    // so the widget never falls back to computing a per-index section
    // key from the full list. `sections` may be empty while the
    // StreamProvider is still loading — the widget simply renders no
    // rail in that case, and re-renders with the rail when the emission
    // lands.
    return AlphabeticalScrollView(
      controller: _scrollController,
      itemExtent: _songRowExtent,
      sectionIndex: sections,
      child: list,
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.song,
    required this.durationLabel,
    required this.onTap,
    required this.onShowMenu,
  });

  final Song song;
  final String durationLabel;
  final VoidCallback onTap;
  final VoidCallback onShowMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cacheSize = (150 * MediaQuery.devicePixelRatioOf(context)).round();

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
        '${song.trackArtistId.value} • $durationLabel',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
        onPressed: onShowMenu,
      ),
      onTap: onTap,
    );
  }
}

/// Static skeleton for rows whose page is not yet in the LRU. No
/// animation, no `CustomPainter`, no shimmer: the intent is a low-cost
/// visual placeholder that keeps the list's scroll physics intact and
/// signals "loading" without burning CPU on the target hardware.
class _SongRowPlaceholder extends StatelessWidget {
  const _SongRowPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.warning,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load library.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
