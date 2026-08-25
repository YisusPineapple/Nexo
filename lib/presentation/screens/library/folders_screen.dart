import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/queue_source.dart';
import '../../providers/grouped_library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/alphabetical_scroll_view.dart';

const double _folderRowExtent = 76.0;

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final theme = Theme.of(context);

    return foldersAsync.when(
      data: (folders) {
        if (folders.isEmpty) {
          return const Center(child: Text('No folders found.'));
        }

        final list = ListView.builder(
          controller: _scrollController,
          itemExtent: _folderRowExtent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FolderDetailScreen(folder: folder),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(PhosphorIconsFill.folder, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(folder.path, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${folder.songCount}', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      const Icon(PhosphorIconsRegular.caretRight, size: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        return AlphabeticalScrollView(
          controller: _scrollController,
          itemCount: folders.length,
          itemExtent: _folderRowExtent,
          labelBuilder: (index) => folders[index].name,
          child: list,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({super.key, required this.folder});

  final FolderUiModel folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(folderSongsProvider(folder.path));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folder.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              folder.path,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      body: songsAsync.when(
        data: (songs) {
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: const Icon(PhosphorIconsRegular.fileAudio),
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.trackArtistId.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  ref.read(playbackControllerProvider.notifier).playSongs(
                        queueIdStr: 'folder_${folder.path}',
                        songs: songs,
                        startIndex: index,
                        source: FolderQueueSource(
                          folderPath: folder.path,
                          folderName: folder.name,
                        ),
                      );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
