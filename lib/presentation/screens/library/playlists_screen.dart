import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/queue_source.dart';
import '../../providers/playback_providers.dart';
import '../../providers/playlist_providers.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(playlistControllerProvider).createPlaylist(name);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      body: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return const Center(child: Text('No playlists yet.'));
          }
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play, size: 40),
                title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    ref.read(playlistControllerProvider).deletePlaylist(playlist.id.value);
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlist: playlist),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          final msg = e is Failure ? e.message : e.toString();
          return Center(child: Text('Error: $msg'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(playlistSongsProvider(playlist.id.value));

    return Scaffold(
      appBar: AppBar(title: Text(playlist.name)),
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('This playlist is empty.'));
          }
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Dismissible(
                key: ValueKey('${song.id.value}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                ),
                onDismissed: (_) {
                  ref.read(playlistControllerProvider).removeSong(playlist.id.value, index);
                },
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: song.coverArtPath != null
                        ? Image.file(File(song.coverArtPath!), width: 48, height: 48, fit: BoxFit.cover, cacheWidth: 150)
                        : Container(
                            width: 48,
                            height: 48,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.music_note),
                          ),
                  ),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.trackArtistId.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    ref.read(playbackControllerProvider.notifier).playSongs(
                          queueIdStr: 'playlist_${playlist.id.value}',
                          songs: songs,
                          startIndex: index,
                          source: PlaylistQueueSource(
                            playlistId: playlist.id.value,
                            playlistName: playlist.name,
                          ),
                        );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          final msg = e is Failure ? e.message : e.toString();
          return Center(child: Text('Error: $msg'));
        },
      ),
    );
  }
}