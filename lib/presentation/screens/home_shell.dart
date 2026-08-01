import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_providers.dart';
import 'library/albums_screen.dart';
import 'library/artists_screen.dart';
import 'library/folders_screen.dart';
import 'library/genres_screen.dart';
import 'library/playlists_screen.dart';
import 'library/songs_screen.dart';

typedef _NavDestination = ({
  String label,
  IconData icon,
  IconData selectedIcon,
});

/// Single source of truth for both the rail and the bar below, and for
/// the IndexedStack order — add a destination here once, not in three
/// places kept in sync by hand.
const _destinations = <_NavDestination>[
  (label: 'Songs', icon: Icons.music_note_outlined, selectedIcon: Icons.music_note),
  (label: 'Albums', icon: Icons.album_outlined, selectedIcon: Icons.album),
  (label: 'Artists', icon: Icons.person_outline, selectedIcon: Icons.person),
  (label: 'Genres', icon: Icons.category_outlined, selectedIcon: Icons.category),
  (label: 'Folders', icon: Icons.folder_outlined, selectedIcon: Icons.folder),
  (label: 'Playlists', icon: Icons.playlist_play_outlined, selectedIcon: Icons.playlist_play),
];

const _screens = <Widget>[
  SongsScreen(),
  AlbumsScreen(),
  ArtistsScreen(),
  GenresScreen(),
  FoldersScreen(),
  PlaylistsScreen(),
];

/// Adaptive shell: [NavigationRail] on wide screens (desktop —
/// Linux/Windows), [NavigationBar] on narrow screens (Android phone).
/// 600dp is Material 3's native compact/medium breakpoint.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _wideBreakpoint = 600.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;

        // Preserves the scroll position and local state of each screen when switching
        // tabs, instead of rebuilding it from scratch each time.
        final body = IndexedStack(index: selectedIndex, children: _screens);

        void onSelect(int i) =>
            ref.read(selectedNavIndexProvider.notifier).state = i;

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
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
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