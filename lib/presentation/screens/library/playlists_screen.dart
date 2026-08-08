import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/queue_source.dart';
import '../../providers/playback_providers.dart';
import '../../providers/playlist_providers.dart';

enum _PlaylistAction { rename, export, delete }

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  Future<void> _showCreateOrRenameDialog(
    BuildContext context,
    WidgetRef ref, {
    Playlist? existingPlaylist,
  }) async {
    final controller =
        TextEditingController(text: existingPlaylist?.name ?? '');
    final theme = Theme.of(context);
    final isRename = existingPlaylist != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRename ? 'Rename Playlist' : 'New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                if (isRename) {
                  ref
                      .read(playlistControllerProvider)
                      .renamePlaylist(existingPlaylist.id.value, name);
                } else {
                  ref.read(playlistControllerProvider).createPlaylist(name);
                }
                Navigator.of(context).pop();
              }
            },
            child: Text(isRename ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(
      BuildContext context, WidgetRef ref, Playlist playlist) async {
    final String? path = await FilePicker.getDirectoryPath();
    if (path == null || !context.mounted) return;

    final error = await ref
        .read(playlistControllerProvider)
        .exportPlaylist(playlist.id.value, path);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(error ?? 'Playlist exported successfully to $path')),
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8'],
    );

    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;

    final error =
        await ref.read(playlistControllerProvider).importPlaylist(path);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Playlist imported successfully')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.downloadSimple),
            tooltip: 'Import .m3u8',
            onPressed: () => _handleImport(context, ref),
          ),
        ],
      ),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(PhosphorIconsFill.playlist,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                title: Text(playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: PopupMenuButton<_PlaylistAction>(
                  icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                  onSelected: (action) {
                    switch (action) {
                      case _PlaylistAction.rename:
                        _showCreateOrRenameDialog(context, ref,
                            existingPlaylist: playlist);
                      case _PlaylistAction.export:
                        _handleExport(context, ref, playlist);
                      case _PlaylistAction.delete:
                        ref
                            .read(playlistControllerProvider)
                            .deletePlaylist(playlist.id.value);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                        value: _PlaylistAction.rename, child: Text('Rename')),
                    PopupMenuItem(
                        value: _PlaylistAction.export,
                        child: Text('Export (.m3u8)')),
                    PopupMenuItem(
                        value: _PlaylistAction.delete, child: Text('Delete')),
                  ],
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
        onPressed: () => _showCreateOrRenameDialog(context, ref),
        child: const Icon(PhosphorIconsRegular.plus),
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
                  child: Icon(PhosphorIconsRegular.trash,
                      color: Theme.of(context).colorScheme.onError),
                ),
                onDismissed: (_) {
                  ref
                      .read(playlistControllerProvider)
                      .removeSong(playlist.id.value, index);
                },
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: song.coverArtPath != null
                        ? Image.file(File(song.coverArtPath!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            cacheWidth: 150)
                        : Container(
                            width: 48,
                            height: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(PhosphorIconsRegular.musicNotes),
                          ),
                  ),
                  title: Text(song.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.trackArtistId.value,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
