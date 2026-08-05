import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failures.dart';
import '../providers/playlist_providers.dart';

class AddToPlaylistDialog extends ConsumerWidget {
  const AddToPlaylistDialog({super.key, required this.songId});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return AlertDialog(
      title: const Text('Add to Playlist'),
      content: SizedBox(
        width: double.maxFinite,
        child: playlistsAsync.when(
          data: (playlists) {
            if (playlists.isEmpty) {
              return const Text('No playlists available. Create one first.');
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  title: Text(playlist.name),
                  onTap: () {
                    ref
                        .read(playlistControllerProvider)
                        .addSong(playlist.id.value, songId);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added to ${playlist.name}')),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) {
            final msg = e is Failure ? e.message : e.toString();
            return Text('Error: $msg');
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
