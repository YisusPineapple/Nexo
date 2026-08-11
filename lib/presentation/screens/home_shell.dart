import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/error/failures.dart';
import '../providers/library_providers.dart';
import '../providers/navigation_providers.dart';
import '../widgets/mini_player.dart';
import 'for_you_screen.dart';
import 'library/library_hub_screen.dart';
import 'library/songs_screen.dart';

typedef _NavDestination = ({
  String label,
  IconData icon,
  IconData selectedIcon,
});

const _destinations = <_NavDestination>[
  (label: 'For You', icon: PhosphorIconsRegular.heart, selectedIcon: PhosphorIconsFill.heart),
  (label: 'Search', icon: PhosphorIconsRegular.magnifyingGlass, selectedIcon: PhosphorIconsFill.magnifyingGlass),
  (label: 'Library', icon: PhosphorIconsRegular.books, selectedIcon: PhosphorIconsFill.books),
];

const _screens = <Widget>[
  ForYouScreen(),
  SongsScreen(),
  LibraryHubScreen(),
];

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _wideBreakpoint = 600.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    final indexState = ref.watch(indexDirectoriesControllerProvider);

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
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        final body = IndexedStack(index: selectedIndex, children: _screens);

        void onSelect(int i) =>
            ref.read(selectedNavIndexProvider.notifier).state = i;

        final miniPlayerWithProgress = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX: Using 'progress != null' directly allows Dart's type promotion to work
            if (progress != null)
              LinearProgressIndicator(
                value: progress.total == 0 ? null : progress.current / progress.total,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            const MiniPlayer(),
          ],
        );

        if (isWide) {
          return Scaffold(
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
        }

        return Scaffold(
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
      },
    );
  }
}