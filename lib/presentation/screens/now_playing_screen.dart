import 'dart:io';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:nexo/domain/entities/repeat_mode.dart';
import '../providers/lyrics_provider.dart';
import '../../domain/entities/lyric_line.dart';

import '../../domain/entities/item_interaction.dart';
import '../providers/playback_providers.dart';
import '../providers/user_metrics_providers.dart';
import 'queue_screen.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({
    super.key,
    this.onClose,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final VoidCallback? onClose;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _showLyrics = false;
  final ScrollController _lyricsScrollController = ScrollController();

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackControllerProvider).valueOrNull;
    final isPlaying = ref.watch(playingStreamProvider).valueOrNull ?? false;
    final position = ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;

    final currentSong = queue?.currentSong;

    if (currentSong == null) {
      return const Scaffold(body: Center(child: Text('No active playback')));
    }

    final duration = currentSong.duration;
    final theme = Theme.of(context);
    final interactionAsync = ref.watch(itemInteractionProvider((id: currentSong.id.value, type: ItemType.song)));
    final interaction = interactionAsync.valueOrNull;

    // FIX: Wrap AppBar in GestureDetector to allow swipe-down to close
    final appBar = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: widget.onVerticalDragUpdate,
      onVerticalDragEnd: widget.onVerticalDragEnd,
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretDown),
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
        title: Text('Now Playing', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showLyrics ? PhosphorIconsRegular.image : PhosphorIconsRegular.microphoneStage),
            tooltip: _showLyrics ? 'Show Cover' : 'Show Lyrics',
            onPressed: () => setState(() => _showLyrics = !_showLyrics),
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.listDashes),
            tooltip: 'Playback Queue',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QueueScreen())),
          ),
        ],
      ),
    );

    // FIX: Wrap CoverArt in GestureDetector to allow swipe-down to close
    final lyricsList = ref.watch(lyricsProvider).valueOrNull ?? const [];
    final currentLyricIndex = ref.watch(currentLyricIndexProvider);

    // Auto-scroll cuando cambia la línea actual.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentLyricIndex >= 0 &&
          currentLyricIndex < lyricsList.length &&
          _lyricsScrollController.hasClients) {
        final targetOffset = currentLyricIndex * 72.0; // ajustar según altura de cada item
        final maxOffset = _lyricsScrollController.position.maxScrollExtent;
        final offset = targetOffset.clamp(0.0, maxOffset);
        _lyricsScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    final coverWidget = GestureDetector(
      onVerticalDragUpdate: widget.onVerticalDragUpdate,
      onVerticalDragEnd: widget.onVerticalDragEnd,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showLyrics
            ? _LyricsView(
                key: const ValueKey('lyrics'),
                lines: lyricsList,
                currentIndex: currentLyricIndex,
                scrollController: _lyricsScrollController,
              )
            : Hero(
                tag: 'cover_${currentSong.id.value}',
                child: _CoverArtView(key: const ValueKey('cover'), coverArtPath: currentSong.coverArtPath),
              ),
      ),
    );

    final controlsWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSong.trackArtistId.value,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(interaction == InteractionType.dislike ? PhosphorIconsFill.heartBreak : PhosphorIconsRegular.heartBreak),
                  color: interaction == InteractionType.dislike ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  onPressed: () => ref.read(userMetricsControllerProvider).toggleInteraction(currentSong.id.value, ItemType.song, InteractionType.dislike),
                ),
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(interaction == InteractionType.like ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart, key: ValueKey(interaction == InteractionType.like)),
                  ),
                  color: interaction == InteractionType.like ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  onPressed: () => ref.read(userMetricsControllerProvider).toggleInteraction(currentSong.id.value, ItemType.song, InteractionType.like),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: theme.colorScheme.primary,
          ),
          child: Slider(
            value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
            max: duration.inMilliseconds.toDouble(),
            onChanged: (value) => ref.read(playbackControllerProvider.notifier).seekTo(Duration(milliseconds: value.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              Text(_formatDuration(duration), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.shuffle),
              color: queue!.shuffleEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              onPressed: () => ref.read(playbackControllerProvider.notifier).toggleShuffle(),
            ),
            IconButton(
              icon: const Icon(PhosphorIconsFill.skipBack),
              iconSize: 40, color: theme.colorScheme.onSurface,
              onPressed: () => ref.read(playbackControllerProvider.notifier).skipPrevious(),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: IconButton(
                padding: const EdgeInsets.all(20),
                iconSize: 40, color: theme.colorScheme.onPrimaryContainer,
                onPressed: () => ref.read(playbackControllerProvider.notifier).togglePlayPause(),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => RotationTransition(turns: Tween<double>(begin: 0.8, end: 1.0).animate(anim), child: ScaleTransition(scale: anim, child: child)),
                  child: Icon(isPlaying ? PhosphorIconsFill.pause : PhosphorIconsFill.play, key: ValueKey(isPlaying)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(PhosphorIconsFill.skipForward),
              iconSize: 40, color: theme.colorScheme.onSurface,
              onPressed: () => ref.read(playbackControllerProvider.notifier).skipNext(),
            ),
            IconButton(
              icon: Icon(queue.repeatMode == RepeatMode.one ? PhosphorIconsRegular.repeatOnce : PhosphorIconsRegular.repeat),
              color: queue.repeatMode != RepeatMode.off ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              onPressed: () => ref.read(playbackControllerProvider.notifier).toggleRepeatMode(),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), theme.colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              appBar,
              Expanded(
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    if (orientation == Orientation.landscape) {
                      return Row(
                        children: [
                          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(32, 0, 16, 32), child: coverWidget)),
                          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 32, 32), child: controlsWidget)),
                        ],
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            Expanded(child: coverWidget),
                            const SizedBox(height: 40),
                            controlsWidget,
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverArtView extends StatelessWidget {
  const _CoverArtView({super.key, this.coverArtPath});
  final String? coverArtPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.25), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 15))],
        ),
        clipBehavior: Clip.antiAlias,
        child: coverArtPath != null
            ? Image.file(File(coverArtPath!), fit: BoxFit.cover, cacheWidth: 600)
            : Icon(PhosphorIconsRegular.musicNotes, size: 100, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _LyricsView extends StatelessWidget {
  const _LyricsView({
    super.key,
    required this.lines,
    required this.currentIndex,
    required this.scrollController,
  });

  final List<LyricLine> lines;
  final int currentIndex;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsRegular.microphoneStage,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No synchronized lyrics found.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: ListView.builder(
        controller: scrollController,
        itemCount: lines.length,
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemBuilder: (context, index) {
          final line = lines[index];
          final isActive = index == currentIndex;
          final theme = Theme.of(context);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              line.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: isActive ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}