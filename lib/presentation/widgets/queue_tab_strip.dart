import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../domain/entities/queue_source.dart';
import '../providers/playback_providers.dart';
import '../providers/queue_manager_provider.dart';

class QueueTabStrip extends ConsumerStatefulWidget {
  const QueueTabStrip({super.key});

  @override
  ConsumerState<QueueTabStrip> createState() => _QueueTabStripState();
}

class _QueueTabStripState extends ConsumerState<QueueTabStrip> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeItemKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive() {
    if (_activeItemKey.currentContext != null) {
      Scrollable.ensureVisible(
        _activeItemKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    }
  }

  IconData _getIconForSource(QueueSource source) {
    return switch (source) {
      AlbumQueueSource() => PhosphorIconsRegular.disc,
      ArtistQueueSource() => PhosphorIconsRegular.user,
      PlaylistQueueSource() => PhosphorIconsRegular.list,
      FolderQueueSource() => PhosphorIconsRegular.folder,
      GenreQueueSource() => PhosphorIconsRegular.tag,
      ManualQueueSource() => PhosphorIconsRegular.musicNotes,
    };
  }

  String _getNameForSource(QueueSource source) {
    return switch (source) {
      AlbumQueueSource(:final albumName) => albumName,
      ArtistQueueSource(:final artistName) => artistName,
      PlaylistQueueSource(:final playlistName) => playlistName,
      FolderQueueSource(:final folderName) => folderName,
      GenreQueueSource(:final genreName) => genreName,
      ManualQueueSource() => 'Queue',
    };
  }

  @override
  Widget build(BuildContext context) {
    final queuesAsync = ref.watch(queueManagerControllerProvider);
    final activeQueue = ref.watch(playbackControllerProvider).valueOrNull;

    ref.listen(playbackControllerProvider, (prev, next) {
      if (prev?.valueOrNull?.id != next.valueOrNull?.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
      }
    });

    return queuesAsync.when(
      data: (queues) {
        if (queues.length <= 1) {
          return const SizedBox.shrink();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
        final theme = Theme.of(context);

        return SizedBox(
          height: 48,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: queues.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final queue = queues[index];
              final isActive = activeQueue?.id == queue.id;

              return Material(
                key: isActive ? _activeItemKey : null,
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (!isActive) {
                      ref
                          .read(playbackControllerProvider.notifier)
                          .switchQueue(queue.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForSource(queue.source),
                          size: 16,
                          color: isActive
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            _getNameForSource(queue.source),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.x),
                          iconSize: 14,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 24, minHeight: 24),
                          color: isActive
                              ? theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7)
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                          onPressed: () {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .closeQueue(queue.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
