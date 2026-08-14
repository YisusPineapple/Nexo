import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/error/failures.dart';
import '../providers/excluded_folders_providers.dart';

class ExcludedFoldersScreen extends ConsumerWidget {
  const ExcludedFoldersScreen({super.key});

  Future<void> _pickAndExclude(BuildContext context, WidgetRef ref) async {
    final String? path;
    try {
      path = await FilePicker.getDirectoryPath();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder picker unavailable: $e')),
      );
      return;
    }

    if (path == null || !context.mounted) return;
    
    await ref.read(excludedFoldersControllerProvider).add(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(excludedFoldersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Excluded Folders'),
      ),
      body: foldersAsync.when(
        data: (folders) {
          if (folders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsRegular.folderNotch,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No excluded folders',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add folders here to prevent Nexo from scanning them (e.g., Podcasts, Audiobooks).',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: Icon(
                  PhosphorIconsRegular.folderNotchMinus,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  folder.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: IconButton(
                  icon: const Icon(PhosphorIconsRegular.trash),
                  color: theme.colorScheme.error,
                  onPressed: () {
                    ref.read(excludedFoldersControllerProvider).remove(folder.id);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndExclude(context, ref),
        icon: const Icon(PhosphorIconsRegular.folderPlus),
        label: const Text('Add Folder'),
      ),
    );
  }
}