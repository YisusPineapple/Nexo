import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexo/domain/entities/queue_source.dart';
import '../../providers/library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../utils/song_sort.dart';
import '../../widgets/add_to_playlist_dialog.dart';
import 'package:nexo/core/error/failures.dart';

class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(songSearchQueryProvider.notifier).state = value;
    });
  }

  Future<void> _pickAndIndexFolder() async {
    final String? path;
    try {
      path = await FilePicker.getDirectoryPath();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder picker unavailable: $e')),
      );
      return;
    }
    if (path == null || !mounted) return;
    await ref
        .read(indexDirectoriesControllerProvider.notifier)
        .indexDirectory(path);
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(sortedSongsProvider);
    final sortOption = ref.watch(songSortOptionProvider);
    final indexState = ref.watch(indexDirectoriesControllerProvider);

    ref.listen(indexDirectoriesControllerProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        final msg = error is Failure ? error.message : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not index folder: $msg')),
        );
      }
    });

    IndexingProgress? progress;
    if (indexState case AsyncData(value: final value?)) {
      progress = value;
    }
    final isIndexing = progress != null;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'Search songs, artists, albums',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Add music folder',
            onPressed: isIndexing ? null : _pickAndIndexFolder,
          ),
          PopupMenuButton<SongSortOption>(
            initialValue: sortOption,
            tooltip: 'Sort by',
            icon: const Icon(Icons.sort),
            onSelected: (option) =>
                ref.read(songSortOptionProvider.notifier).state = option,
            itemBuilder: (context) => [
              for (final option in SongSortOption.values)
                PopupMenuItem(value: option, child: Text(option.label)),
            ],
          ),
        ],
        bottom: isIndexing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: progress.total == 0
                      ? null
                      : progress.current / progress.total,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          if (isIndexing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Indexing ${progress.current} of ${progress.total}...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: songsAsync.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No songs found.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: isIndexing ? null : _pickAndIndexFolder,
                          icon: const Icon(Icons.create_new_folder_outlined),
                          label: const Text('Add music folder'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemExtent: 72,
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
                        // <--- AÑADIR ESTO
                        icon: const Icon(Icons.playlist_add),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                AddToPlaylistDialog(songId: song.id.value),
                          );
                        },
                      ),
                      onTap: () {
                        ref.read(playbackControllerProvider.notifier).playSongs(
                              queueIdStr: 'library_songs',
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
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
