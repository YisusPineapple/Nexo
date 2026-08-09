import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../providers/navigation_providers.dart';
import '../widgets/mini_player.dart';
import 'for_you_screen.dart'; // NEW IMPORT
import 'library/albums_screen.dart';
import 'library/artists_screen.dart';
import 'library/folders_screen.dart';
import 'library/genres_screen.dart';
import 'library/playlists_screen.dart';
import 'library/songs_screen.dart';
import 'settings_screen.dart';

typedef _NavDestination = ({
  String label,
  IconData icon,
  IconData selectedIcon,
});

const _destinations = <_NavDestination>[
  // NEW: For You at index 0
  (label: 'For You', icon: PhosphorIconsRegular.heart, selectedIcon: PhosphorIconsFill.heart),
  (label: 'Songs', icon: PhosphorIconsRegular.musicNotes, selectedIcon: PhosphorIconsFill.musicNotes),
  (label: 'Albums', icon: PhosphorIconsRegular.disc, selectedIcon: PhosphorIconsFill.disc),
  (label: 'Artists', icon: PhosphorIconsRegular.users, selectedIcon: PhosphorIconsFill.users),
  (label: 'Genres', icon: PhosphorIconsRegular.books, selectedIcon: PhosphorIconsFill.books),
  (label: 'Folders', icon: PhosphorIconsRegular.folder, selectedIcon: PhosphorIconsFill.folderOpen),
  (label: 'Playlists', icon: PhosphorIconsRegular.playlist, selectedIcon: PhosphorIconsFill.playlist),
  (label: 'Settings', icon: PhosphorIconsRegular.gear, selectedIcon: PhosphorIconsFill.gear),
];

const _screens = <Widget>[
  ForYouScreen(), // NEW: Index 0
  SongsScreen(),
  AlbumsScreen(),
  ArtistsScreen(),
  GenresScreen(),
  FoldersScreen(),
  PlaylistsScreen(),
  SettingsScreen(),
];

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _wideBreakpoint = 600.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
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
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: body),
                      const MiniPlayer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              Expanded(child: body),
              const MiniPlayer(),
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