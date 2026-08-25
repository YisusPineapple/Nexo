import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/error/failures.dart';
import '../providers/library_providers.dart';
import '../providers/navigation_providers.dart';
import '../providers/playback_providers.dart'; // FIX: Added to watch queue state
import '../widgets/mini_player.dart';
import 'for_you_screen.dart';
import 'library/library_hub_screen.dart';
import 'now_playing_screen.dart';
import 'search_screen.dart';

typedef _NavDestination = ({
  String label,
  IconData icon,
  IconData selectedIcon,
});

const _destinations = <_NavDestination>[
  (
    label: 'For You',
    icon: PhosphorIconsRegular.heart,
    selectedIcon: PhosphorIconsFill.heart
  ),
  (
    label: 'Search',
    icon: PhosphorIconsRegular.magnifyingGlass,
    selectedIcon: PhosphorIconsFill.magnifyingGlass
  ),
  (
    label: 'Library',
    icon: PhosphorIconsRegular.books,
    selectedIcon: PhosphorIconsFill.books
  ),
];

const _screens = <Widget>[
  ForYouScreen(),
  SearchScreen(),
  LibraryHubScreen(),
];

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  static const _wideBreakpoint = 600.0;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _playerAnim;
  final GlobalKey _indexedStackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _playerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    if (Platform.isAndroid) {
      Permission.notification.request();
    }
  }

  @override
  void dispose() {
    _playerAnim.dispose();
    super.dispose();
  }

  void _togglePlayer() {
    if (_playerAnim.isDismissed) {
      _playerAnim.forward();
    } else {
      _playerAnim.reverse();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = -details.primaryDelta! / MediaQuery.of(context).size.height;
    _playerAnim.value += delta;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_playerAnim.isDismissed || _playerAnim.isCompleted) return;

    if (details.primaryVelocity! < -300) {
      _playerAnim.forward();
    } else if (details.primaryVelocity! > 300) {
      _playerAnim.reverse();
    } else if (_playerAnim.value > 0.5) {
      _playerAnim.forward();
    } else {
      _playerAnim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    final indexState = ref.watch(indexDirectoriesControllerProvider);
    
    // FIX: Watch the queue to know if the MiniPlayer is visible
    final queueAsync = ref.watch(playbackControllerProvider);
    final hasQueue = queueAsync.valueOrNull != null;

    ref.listen(indexDirectoriesControllerProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        final msg = error is Failure ? error.message : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not index folder: $msg')),
        );
      }
    });

    IndexingProgress? progress;
    if (indexState case AsyncData(value: final value?)) {
      progress = value;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= HomeShell._wideBreakpoint;

        // FIX: Dynamic bottom padding. 80px reserves space for the MiniPlayer (68px height + 12px margin)
        // This single source of truth prevents the MiniPlayer from covering the last items in ANY screen.
        final body = Padding(
          padding: EdgeInsets.only(bottom: hasQueue ? 80.0 : 0.0),
          child: IndexedStack(
            key: _indexedStackKey,
            index: selectedIndex,
            children: _screens,
          ),
        );

        void onSelect(int i) =>
            ref.read(selectedNavIndexProvider.notifier).state = i;

        final miniPlayerWithProgress = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress != null)
              LinearProgressIndicator(
                value: progress.total == 0
                    ? null
                    : progress.current / progress.total,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            AnimatedBuilder(
              animation: _playerAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: (1.0 - (_playerAnim.value * 2)).clamp(0.0, 1.0),
                  child: IgnorePointer(
                    ignoring: _playerAnim.value > 0.5,
                    child: child,
                  ),
                );
              },
              child: MiniPlayer(
                onTap: _togglePlayer,
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: _handleDragEnd,
              ),
            ),
          ],
        );

        Widget scaffold;
        if (isWide) {
          scaffold = Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelect,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Stack(
                    children: [
                      body,
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: miniPlayerWithProgress,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          scaffold = Scaffold(
            body: Stack(
              children: [
                body,
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: miniPlayerWithProgress,
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          );
        }

        return AnimatedBuilder(
          animation: _playerAnim,
          child: scaffold,
          builder: (context, child) {
            return PopScope(
              canPop: _playerAnim.isDismissed,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && !_playerAnim.isDismissed) {
                  _playerAnim.reverse();
                }
              },
              child: Stack(
                children: [
                  child!,
                  if (_playerAnim.value > 0)
                    Transform.translate(
                      offset: Offset(
                        0,
                        constraints.maxHeight * (1 - _playerAnim.value),
                      ),
                      child: NowPlayingScreen(
                        onClose: _togglePlayer,
                        onVerticalDragUpdate: _handleDragUpdate,
                        onVerticalDragEnd: _handleDragEnd,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}