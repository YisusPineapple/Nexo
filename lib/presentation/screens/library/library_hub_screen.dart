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
import 'songs_screen.dart';

// FIX: StateProvider to preserve the selected tab across rotations
final libraryTabProvider = StateProvider<int>((ref) => 0);

class LibraryHubScreen extends ConsumerStatefulWidget {
  const LibraryHubScreen({super.key});

  @override
  ConsumerState<LibraryHubScreen> createState() => _LibraryHubScreenState();
}

class _LibraryHubScreenState extends ConsumerState<LibraryHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: ref.read(libraryTabProvider),
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(libraryTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indexState = ref.watch(indexDirectoriesControllerProvider);
    final isIndexing = indexState is AsyncData && indexState.value != null;
    final progress = indexState.valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.folderPlus),
            tooltip: 'Manage folders',
            onPressed: isIndexing ? null : () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FolderManagementScreen()));
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.gear),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Songs'), // FIX: Songs is now the default tab
            Tab(text: 'Playlists'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Folders'),
            Tab(text: 'Genres'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (isIndexing && progress != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Scanning library... ${progress.current} / ${progress.total}',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SongsScreen(),
                PlaylistsScreen(),
                AlbumsScreen(),
                ArtistsScreen(),
                FoldersScreen(),
                GenresScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}