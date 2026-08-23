import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../domain/entities/song.dart';
import 'add_to_playlist_dialog.dart';

class SongContextMenu extends StatelessWidget {
  const SongContextMenu({super.key, required this.song});

  final Song song;

  void _showSongInfo(BuildContext context) {
    Navigator.pop(context); // Close the bottom sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Song Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (song.coverArtPath != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(song.coverArtPath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Title', value: song.title),
              _InfoRow(label: 'Artist', value: song.trackArtistId.value),
              _InfoRow(label: 'Album', value: song.albumId?.value ?? 'Unknown'),
              _InfoRow(label: 'Format', value: song.format.name.toUpperCase()),
              _InfoRow(
                label: 'Size',
                value: '${(song.fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
              ),
              _InfoRow(label: 'File Path', value: song.filePath),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: song.coverArtPath != null
                      ? Image.file(
                          File(song.coverArtPath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(PhosphorIconsRegular.musicNotes),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        song.trackArtistId.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.info),
            title: const Text('Song info'),
            onTap: () => _showSongInfo(context),
          ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.listPlus),
            title: const Text('Add to playlist'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AddToPlaylistDialog(songId: song.id.value),
              );
            },
          ),
          // Placeholders for the next iteration
          ListTile(
            leading: const Icon(PhosphorIconsRegular.queue),
            title: const Text('Add to queue'),
            enabled: false, // TODO: Implement in next phase
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.skipForward),
            title: const Text('Play next'),
            enabled: false, // TODO: Implement in next phase
            onTap: () {},
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}