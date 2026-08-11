import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../providers/library_providers.dart';
import '../settings_screen.dart';
import 'albums_screen.dart';
import 'artists_screen.dart';
import 'folders_screen.dart';
import 'genres_screen.dart';
import 'playlists_screen.dart';

class LibraryHubScreen extends ConsumerWidget {
  const LibraryHubScreen({super.key});

  Future<void> _pickAndIndexFolder(BuildContext context, WidgetRef ref) async {
    final String? path;
    try {
      // FIX: Removed .platform as required by the current file_picker version
      path = await FilePicker.getDirectoryPath();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder picker unavailable: $e')),
      );
      return;
    }
    if (path == null || !context.mounted) return;
    await ref.read(indexDirectoriesControllerProvider.notifier).indexDirectory(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexState = ref.watch(indexDirectoriesControllerProvider);
    final isIndexing = indexState is AsyncData && indexState.value != null;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.folderPlus),
              tooltip: 'Add music folder',
              onPressed: isIndexing ? null : () => _pickAndIndexFolder(context, ref),
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