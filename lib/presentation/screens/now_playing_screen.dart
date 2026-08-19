import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:nexo/domain/entities/repeat_mode.dart';
import '../../domain/entities/app_preferences.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/lyrics_provider.dart';
import '../../domain/entities/lyric_line.dart';
import '../../domain/entities/lyric_segment.dart';

import '../../domain/entities/item_interaction.dart';
import '../providers/playback_providers.dart';
import '../providers/user_metrics_providers.dart';
import '../widgets/animated_interaction_button.dart';
import '../widgets/marquee_text.dart';
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
  bool _isFullScreen = false;
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

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackControllerProvider).valueOrNull;
    final isPlaying = ref.watch(playingStreamProvider).valueOrNull ?? false;
    final position =
        ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;

    final currentSong = queue?.currentSong;

    if (currentSong == null) {
      return const Scaffold(body: Center(child: Text('No active playback')));
    }

    final duration = currentSong.duration;
    final theme = Theme.of(context);
    final interactionAsync = ref.watch(itemInteractionProvider(
        (id: currentSong.id.value, type: ItemType.song)));
    final interaction = interactionAsync.valueOrNull;

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
        title: Text('Now Playing',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showLyrics
                ? PhosphorIconsRegular.image
                : PhosphorIconsRegular.microphoneStage),
            tooltip: _showLyrics ? 'Show Cover' : 'Show Lyrics',
            onPressed: () {
              setState(() {
                _showLyrics = !_showLyrics;
                if (!_showLyrics) _isFullScreen = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.listDashes),
            tooltip: 'Playback Queue',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const QueueScreen())),
          ),
        ],
      ),
    );

    final lyricsList = ref.watch(lyricsProvider).valueOrNull ?? const [];
    final currentLyricIndex = ref.watch(currentLyricIndexProvider);
    final currentSegment = ref.watch(currentLyricSegmentProvider);

    final prefs = ref.watch(appPreferencesProvider);
    
    final double itemExtent = switch (prefs.lyricsFontSize) {
      LyricsFontSize.small => 100.0,
      LyricsFontSize.medium => 120.0,
      LyricsFontSize.large => 150.0,
      LyricsFontSize.extraLarge => 180.0,
    };

    ref.listen<int>(currentLyricIndexProvider, (previous, next) {
      if (previous != next &&
          next >= 0 &&
          next < lyricsList.length &&
          _lyricsScrollController.hasClients) {
        final targetOffset = next * itemExtent;
        final maxOffset = _lyricsScrollController.position.maxScrollExtent;
        final offset = targetOffset.clamp(0.0, maxOffset);

        _lyricsScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
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
                ref: ref,
                lines: lyricsList,
                currentIndex: currentLyricIndex,
                activeSegment: currentSegment,
                scrollController: _lyricsScrollController,
                onToggleFullScreen: _toggleFullScreen,
                isFullScreen: _isFullScreen,
                itemExtent: itemExtent,
              )
            : Hero(
                tag: 'cover_${currentSong.id.value}',
                child: _CoverArtView(
                    key: const ValueKey('cover'),
                    coverArtPath: currentSong.coverArtPath),
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
                  MarqueeText(
                    text: currentSong.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSong.trackArtistId.value,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedInteractionButton(
                  icon: interaction == InteractionType.dislike
                      ? PhosphorIconsFill.heartBreak
                      : PhosphorIconsRegular.heartBreak,
                  color: interaction == InteractionType.dislike
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  isActive: interaction == InteractionType.dislike,
                  showBurst: false, // FIX: No burst for dislike
                  onPressed: () => ref
                      .read(userMetricsControllerProvider)
                      .toggleInteraction(currentSong.id.value, ItemType.song,
                          InteractionType.dislike),
                ),
                AnimatedInteractionButton(
                  icon: interaction == InteractionType.like
                      ? PhosphorIconsFill.heart
                      : PhosphorIconsRegular.heart,
                  color: interaction == InteractionType.like
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  isActive: interaction == InteractionType.like,
                  showBurst: true, // Burst for like
                  onPressed: () => ref
                      .read(userMetricsControllerProvider)
                      .toggleInteraction(currentSong.id.value, ItemType.song,
                          InteractionType.like),
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
            inactiveTrackColor:
                theme.colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: theme.colorScheme.primary,
          ),
          child: Slider(
            value: position.inMilliseconds
                .toDouble()
                .clamp(0, duration.inMilliseconds.toDouble()),
            max: duration.inMilliseconds.toDouble(),
            onChanged: (value) => ref
                .read(playbackControllerProvider.notifier)
                .seekTo(Duration(milliseconds: value.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              Text(_formatDuration(duration),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.shuffle),
              color: queue!.shuffleEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              onPressed: () =>
                  ref.read(playbackControllerProvider.notifier).toggleShuffle(),
            ),
            IconButton(
              icon: const Icon(PhosphorIconsFill.skipBack),
              iconSize: 40,
              color: theme.colorScheme.onSurface,
              onPressed: () =>
                  ref.read(playbackControllerProvider.notifier).skipPrevious(),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8))
                ],
              ),
              child: IconButton(
                padding: const EdgeInsets.all(20),
                iconSize: 40,
                color: theme.colorScheme.onPrimaryContainer,
                onPressed: () => ref
                    .read(playbackControllerProvider.notifier)
                    .togglePlayPause(),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween<double>(begin: 0.8, end: 1.0).animate(anim),
                      child: ScaleTransition(scale: anim, child: child)),
                  child: Icon(
                      isPlaying
                          ? PhosphorIconsFill.pause
                          : PhosphorIconsFill.play,
                      key: ValueKey(isPlaying)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(PhosphorIconsFill.skipForward),
              iconSize: 40,
              color: theme.colorScheme.onSurface,
              onPressed: () =>
                  ref.read(playbackControllerProvider.notifier).skipNext(),
            ),
            IconButton(
              icon: Icon(queue.repeatMode == RepeatMode.one
                  ? PhosphorIconsRegular.repeatOnce
                  : PhosphorIconsRegular.repeat),
              color: queue.repeatMode != RepeatMode.off
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              onPressed: () => ref
                  .read(playbackControllerProvider.notifier)
                  .toggleRepeatMode(),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              theme.colorScheme.surface
            ],
          ),
        ),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: _isFullScreen
                          ? const SizedBox(width: double.infinity, height: 0)
                          : appBar,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: _isFullScreen ? 2 : 1,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(32, 0, _isFullScreen ? 32 : 16, 32),
                              child: coverWidget,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            child: _isFullScreen
                                ? const SizedBox(width: 0)
                                : SizedBox(
                                    width: MediaQuery.of(context).size.width / 2,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 32, 32),
                                      child: controlsWidget,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: _isFullScreen
                          ? const SizedBox(width: double.infinity, height: 0)
                          : appBar,
                    ),
                    Expanded(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        padding: EdgeInsets.symmetric(
                            horizontal: _isFullScreen ? 16.0 : 32.0),
                        child: coverWidget,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: _isFullScreen
                          ? const SizedBox(width: double.infinity, height: 0)
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  controlsWidget,
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              }
            },
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
          boxShadow: [
            BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 15))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: coverArtPath != null
            ? Image.file(File(coverArtPath!),
                fit: BoxFit.cover, cacheWidth: 600)
            : Icon(PhosphorIconsRegular.musicNotes,
                size: 100, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _LyricsView extends ConsumerWidget {
  const _LyricsView({
    super.key,
    required this.ref,
    required this.lines,
    required this.currentIndex,
    required this.activeSegment,
    required this.scrollController,
    required this.onToggleFullScreen,
    required this.isFullScreen,
    required this.itemExtent,
  });

  final WidgetRef ref;
  final List<LyricLine> lines;
  final int currentIndex;
  final LyricSegment? activeSegment;
  final ScrollController scrollController;
  final VoidCallback onToggleFullScreen;
  final bool isFullScreen;
  final double itemExtent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(appPreferencesProvider);

    final textAlign = switch (prefs.lyricsAlignment) {
      LyricsAlignment.left => TextAlign.left,
      LyricsAlignment.center => TextAlign.center,
      LyricsAlignment.right => TextAlign.right,
      LyricsAlignment.justify => TextAlign.justify,
    };

    final wrapAlignment = switch (prefs.lyricsAlignment) {
      LyricsAlignment.left => WrapAlignment.start,
      LyricsAlignment.center => WrapAlignment.center,
      LyricsAlignment.right => WrapAlignment.end,
      LyricsAlignment.justify => WrapAlignment.spaceBetween,
    };

    final crossAxisAlignment = switch (prefs.lyricsAlignment) {
      LyricsAlignment.left => CrossAxisAlignment.start,
      LyricsAlignment.center => CrossAxisAlignment.center,
      LyricsAlignment.right => CrossAxisAlignment.end,
      LyricsAlignment.justify => CrossAxisAlignment.stretch,
    };

    final baseFontSize = switch (prefs.lyricsFontSize) {
      LyricsFontSize.small => 14.0,
      LyricsFontSize.medium => 18.0,
      LyricsFontSize.large => 22.0,
      LyricsFontSize.extraLarge => 26.0,
    };

    if (lines.isEmpty) {
      return GestureDetector(
        onTap: onToggleFullScreen,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.microphoneStage,
                  size: 48,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No synchronized lyrics found.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final verticalPadding = (constraints.maxHeight - itemExtent) / 2;

        return Stack(
          children: [
            GestureDetector(
              onTap: onToggleFullScreen,
              behavior: HitTestBehavior.translucent,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  key: const PageStorageKey('lyrics_list'),
                  controller: scrollController,
                  itemCount: lines.length,
                  itemExtent: itemExtent,
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding > 0 ? verticalPadding : 32.0,
                  ),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final isActive = index == currentIndex;
                    final distance = (index - currentIndex).abs();
                    final currentLineActiveSegment = isActive ? activeSegment : null;

                    final double blurSigma = prefs.lyricsBlurEnabled
                        ? (isActive ? 0.0 : (distance * 0.8).clamp(0.0, 3.0))
                        : 0.0;
                    final double opacity = isActive
                        ? 1.0
                        : (1.0 - (distance * 0.18)).clamp(0.25, 0.75);
                    final double scale = isActive ? 1.0 : 0.96;

                    final useWordSync = prefs.lyricsHighlightWords && line.segments.length > 1;

                    final lyricText = useWordSync
                        ? Wrap(
                            alignment: wrapAlignment,
                            spacing: 5,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < line.segments.length; i++)
                                _LyricSegmentChip(
                                  segment: line.segments[i],
                                  isActive: currentLineActiveSegment == line.segments[i],
                                  theme: theme,
                                  fontSize: baseFontSize,
                                ),
                            ],
                          )
                        : Text(
                            line.fullText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              fontSize: isActive ? baseFontSize : baseFontSize - 2,
                              height: 1.4,
                            ),
                            textAlign: textAlign,
                          );

                    Widget lineContent = Center(child: lyricText);

                    if (blurSigma > 0.0) {
                      lineContent = ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                        child: lineContent,
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        ref.read(playbackControllerProvider.notifier).seekTo(line.lineTimestamp);
                      },
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: opacity,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 250),
                          scale: scale,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: crossAxisAlignment,
                              children: [lineContent],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isFullScreen ? PhosphorIconsRegular.cornersIn : PhosphorIconsRegular.cornersOut,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                onPressed: onToggleFullScreen,
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              bottom: isFullScreen ? 16 : -70,
              right: 16,
              child: const _OffsetControls(),
            ),
          ],
        );
      },
    );
  }
}

class _LyricSegmentChip extends StatelessWidget {
  const _LyricSegmentChip({
    required this.segment,
    required this.isActive,
    required this.theme,
    required this.fontSize,
  });

  final LyricSegment segment;
  final bool isActive;
  final ThemeData theme;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: theme.textTheme.bodyLarge!.copyWith(
        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.75),
        fontSize: isActive ? fontSize + 0.5 : fontSize,
        height: 1.4,
      ),
      child: Text(segment.text),
    );
  }
}

class _OffsetControls extends ConsumerWidget {
  const _OffsetControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(lyricOffsetProvider);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(32),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.caretDoubleLeft, size: 16),
              tooltip: 'Delay -1.0s',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final current = ref.read(lyricOffsetProvider);
                if (current > -5000) {
                  ref.read(lyricOffsetProvider.notifier).state =
                      (current - 1000).clamp(-5000, 5000);
                }
              },
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.minus, size: 16),
              tooltip: 'Delay -0.1s',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final current = ref.read(lyricOffsetProvider);
                if (current > -5000) {
                  ref.read(lyricOffsetProvider.notifier).state =
                      (current - 100).clamp(-5000, 5000);
                }
              },
            ),
            InkWell(
              onTap: () => ref.read(lyricOffsetProvider.notifier).state = 0,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  '${offset > 0 ? '+' : ''}${(offset / 1000).toStringAsFixed(1)}s',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.bold,
                    color: offset == 0
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.plus, size: 16),
              tooltip: 'Advance +0.1s',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final current = ref.read(lyricOffsetProvider);
                if (current < 5000) {
                  ref.read(lyricOffsetProvider.notifier).state =
                      (current + 100).clamp(-5000, 5000);
                }
              },
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.caretDoubleRight, size: 16),
              tooltip: 'Advance +1.0s',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final current = ref.read(lyricOffsetProvider);
                if (current < 5000) {
                  ref.read(lyricOffsetProvider.notifier).state =
                      (current + 1000).clamp(-5000, 5000);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}