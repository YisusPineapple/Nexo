import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../providers/library_providers.dart';
import '../settings_screen.dart';
import 'albums_screen.dart';
import 'artists_screen.dart';
import 'folder_management_screen.dart';
import 'folders_screen.dart';
import 'genres_screen.dart';
import 'playlists_screen.dart';

class LibraryHubScreen extends ConsumerWidget {
  const LibraryHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexState = ref.watch(indexDirectoriesControllerProvider);
    final isIndexing = indexState is AsyncData && indexState.value != null;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.folderPlus),
              tooltip: 'Manage folders',
              onPressed: isIndexing
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const FolderManagementScreen()),
                      );
                    },
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.gear),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Albums'),
              Tab(text: 'Artists'),
              Tab(text: 'Folders'),
              Tab(text: 'Genres'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PlaylistsScreen(),
            AlbumsScreen(),
            ArtistsScreen(),
            FoldersScreen(),
            GenresScreen(),
          ],
        ),
      ),
    );
  }
}
