import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/queue_source.dart';
import '../../providers/library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../utils/song_sort.dart';
import '../../widgets/add_to_playlist_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(sortedSongsProvider);
    final sortOption = ref.watch(songSortOptionProvider);

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
          PopupMenuButton<SongSortOption>(
            initialValue: sortOption,
            tooltip: 'Sort by',
            icon: const Icon(PhosphorIconsRegular.arrowsDownUp),
            onSelected: (option) =>
                ref.read(songSortOptionProvider.notifier).state = option,
            itemBuilder: (context) => [
              for (final option in SongSortOption.values)
                PopupMenuItem(value: option, child: Text(option.label)),
            ],
          ),
        ],
      ),
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(
              child: Text('No songs found. Go to Library to add a folder.'),
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
                  icon: const Icon(PhosphorIconsRegular.listPlus),
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
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}