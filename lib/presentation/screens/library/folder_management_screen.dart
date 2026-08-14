import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/error/failures.dart';
import '../../providers/library_folder_providers.dart';

class FolderManagementScreen extends ConsumerWidget {
  const FolderManagementScreen({super.key});

  Future<void> _pickFolder(
    BuildContext context,
    WidgetRef ref, {
    required bool isExclusion,
  }) async {
    final String? path;
    try {
      path = await FilePicker.platform.getDirectoryPath();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder picker unavailable: $e')),
      );
      return;
    }

    if (path == null || !context.mounted) return;

    final controller = ref.read(folderManagementControllerProvider);
    final String? error;
    if (isExclusion) {
      error = await controller.addExcludedFolder(path);
    } else {
      error = await controller.addIndexedFolder(path);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? (isExclusion
            ? 'Folder excluded successfully.'
            : 'Folder added and indexing started.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexedAsync = ref.watch(indexedFoldersProvider);
    final excludedAsync = ref.watch(excludedFoldersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Folders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Music Folders',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'These folders are scanned for music files.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          indexedAsync.when(
            data: (folders) {
              if (folders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No folders added yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final folder in folders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        PhosphorIconsFill.folderOpen,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        folder.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Added ${_formatDate(folder.dateAddedUtc)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          PhosphorIconsRegular.trash,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () async {
                          final error = await ref
                              .read(folderManagementControllerProvider)
                              .removeIndexedFolder(folder.path);
                          if (context.mounted && error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) {
              final msg = e is Failure ? e.message : e.toString();
              return Text('Error: $msg');
            },
          ),
          FilledButton.icon(
            onPressed: () => _pickFolder(context, ref, isExclusion: false),
            icon: const Icon(PhosphorIconsRegular.folderPlus),
            label: const Text('Add Music Folder'),
          ),
          const Divider(height: 40),
          Text(
            'Excluded Folders',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'These folders are skipped during scanning. Useful for podcasts, audiobooks, or ringtones inside your music directory.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          excludedAsync.when(
            data: (folders) {
              if (folders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No exclusions configured.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final folder in folders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        PhosphorIconsFill.folderNotchMinus,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        folder.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Excluded ${_formatDate(folder.dateAddedUtc)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          PhosphorIconsRegular.trash,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () async {
                          final error = await ref
                              .read(folderManagementControllerProvider)
                              .removeExcludedFolder(folder.path);
                          if (context.mounted && error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) {
              final msg = e is Failure ? e.message : e.toString();
              return Text('Error: $msg');
            },
          ),
          OutlinedButton.icon(
            onPressed: () => _pickFolder(context, ref, isExclusion: true),
            icon: const Icon(PhosphorIconsRegular.folderNotchPlus),
            label: const Text('Add Exclusion'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}