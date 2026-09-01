import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../domain/entities/song.dart';
import '../../../domain/entities/queue_source.dart';
import '../providers/for_you_provider.dart';
import '../providers/playback_providers.dart';
import 'settings_screen.dart';

class ForYouScreen extends ConsumerWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forYouControllerProvider);

    return Scaffold(
      body: state.when(
        data: (data) {
          if (data.isEmpty) {
            return _EmptyState(
              onRefresh: () =>
                  ref.read(forYouControllerProvider.notifier).refresh(),
            );
          }
          return _ForYouContent(data: data, ref: ref);
        },
        loading: () => const _ForYouSkeleton(),
        error: (error, stack) => _ErrorState(
          error: error,
          onRetry: () => ref.read(forYouControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _ForYouContent extends StatelessWidget {
  const _ForYouContent({required this.data, required this.ref});

  final ForYouData data;
  final WidgetRef ref;

  void _playList(List<Song> songs, int startIndex, QueueSource source) {
    ref.read(playbackControllerProvider.notifier).playSongs(
          queueIdStr: 'for_you_queue',
          songs: songs,
          startIndex: startIndex,
          source: source,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.gear),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your musical oasis awaits.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (data.recentlyPlayed.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Recently Played',
              icon: PhosphorIconsRegular.clockClockwise,
              onPlayAll: () => _playList(
                data.recentlyPlayed,
                0,
                const ManualQueueSource(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalSongList(
              songs: data.recentlyPlayed,
              onTap: (index) => _playList(
                data.recentlyPlayed,
                index,
                const ManualQueueSource(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        if (data.dailyMix.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Your Daily Mix',
              icon: PhosphorIconsRegular.sparkle,
              onPlayAll: () => _playList(
                data.dailyMix,
                0,
                const ManualQueueSource(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalSongList(
              songs: data.dailyMix,
              onTap: (index) => _playList(
                data.dailyMix,
                index,
                const ManualQueueSource(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        if (data.topTracks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Your Top Tracks',
              icon: PhosphorIconsRegular.trophy,
              onPlayAll: () => _playList(
                data.topTracks,
                0,
                const ManualQueueSource(),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = data.topTracks[index];
                return _VerticalSongTile(
                  song: song,
                  rank: index + 1,
                  onTap: () => _playList(
                    data.topTracks,
                    index,
                    const ManualQueueSource(),
                  ),
                );
              },
              childCount: data.topTracks.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onPlayAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onPlayAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onPlayAll != null)
            TextButton.icon(
              onPressed: onPlayAll,
              icon: const Icon(PhosphorIconsRegular.play, size: 16),
              label: const Text('Play All'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _HorizontalSongList extends StatelessWidget {
  const _HorizontalSongList({
    required this.songs,
    required this.onTap,
  });

  final List<Song> songs;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final song = songs[index];
          return _SmallSongCard(
            song: song,
            onTap: () => onTap(index),
          );
        },
      ),
    );
  }
}

class _SmallSongCard extends StatelessWidget {
  const _SmallSongCard({
    required this.song,
    required this.onTap,
  });

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: song.coverArtPath != null
                      ? Image.file(
                          File(song.coverArtPath!),
                          fit: BoxFit.cover,
                          cacheWidth: 200,
                        )
                      : Icon(
                          PhosphorIconsRegular.musicNotes,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
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
    );
  }
}

class _VerticalSongTile extends StatelessWidget {
  const _VerticalSongTile({
    required this.song,
    required this.rank,
    required this.onTap,
  });

  final Song song;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: song.coverArtPath != null
            ? Image.file(
                File(song.coverArtPath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                cacheWidth: 150,
              )
            : Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(PhosphorIconsRegular.musicNotes),
              ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        song.trackArtistId.value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '#$rank',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.heartStraight,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start building your musical footprint!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Listen to songs and like your favorites to see your personal mixes here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              PhosphorIconsRegular.warning,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForYouSkeleton extends StatelessWidget {
  const _ForYouSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 24,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 16,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 16,
              width: 100,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: List.generate(5, (index) {
                return Container(
                  width: 100,
                  height: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
