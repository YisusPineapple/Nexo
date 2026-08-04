import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/song.dart';
import '../../domain/value_objects/album_id.dart';
import '../../domain/value_objects/artist_id.dart';
import 'library_providers.dart';
import 'repository_providers.dart';

typedef AlbumUiModel = ({
  String id,
  String name,
  String artist,
  String? coverArtPath,
  int songCount
});
typedef ArtistUiModel = ({
  String name,
  int songCount,
  int albumCount,
  String? coverArtPath
});
typedef GenreUiModel = ({String name, int songCount});
typedef FolderUiModel = ({String path, String name, int songCount});

/// Groups all indexed songs by Album using a background isolate to prevent UI jank.
final albumsProvider = FutureProvider<List<AlbumUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);

  return Isolate.run(() {
    final map = <String, AlbumUiModel>{};
    for (final song in songs) {
      final albumId = song.albumId?.value;
      if (albumId == null) continue;

      if (!map.containsKey(albumId)) {
        map[albumId] = (
          id: albumId,
          name: albumId,
          artist: song.albumArtistId?.value ?? song.trackArtistId.value,
          coverArtPath: song.coverArtPath,
          songCount: 1,
        );
      } else {
        final existing = map[albumId]!;
        map[albumId] = (
          id: existing.id,
          name: existing.name,
          artist: existing.artist,
          coverArtPath: existing.coverArtPath ?? song.coverArtPath,
          songCount: existing.songCount + 1,
        );
      }
    }
    return map.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });
});

/// Groups all indexed songs by Artist.
final artistsProvider = FutureProvider<List<ArtistUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);

  return Isolate.run(() {
    final map = <String, ArtistUiModel>{};
    final artistAlbums = <String, Set<String>>{};

    for (final song in songs) {
      final artist = song.trackArtistId.value;
      artistAlbums.putIfAbsent(artist, () => {}).add(song.albumId?.value ?? '');

      if (!map.containsKey(artist)) {
        map[artist] = (
          name: artist,
          songCount: 1,
          albumCount: 0, // Computed at the end
          coverArtPath: song.coverArtPath,
        );
      } else {
        final existing = map[artist]!;
        map[artist] = (
          name: existing.name,
          songCount: existing.songCount + 1,
          albumCount: 0,
          coverArtPath: existing.coverArtPath ?? song.coverArtPath,
        );
      }
    }

    return map.values
        .map((a) => (
              name: a.name,
              songCount: a.songCount,
              albumCount:
                  artistAlbums[a.name]!.where((al) => al.isNotEmpty).length,
              coverArtPath: a.coverArtPath,
            ))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });
});

/// Groups all indexed songs by Genre.
final genresProvider = FutureProvider<List<GenreUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);

  return Isolate.run(() {
    final map = <String, int>{};
    for (final song in songs) {
      for (final genre in song.genreNames) {
        map[genre] = (map[genre] ?? 0) + 1;
      }
    }
    return map.entries.map((e) => (name: e.key, songCount: e.value)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });
});

/// Groups all indexed songs by their parent directory.
final foldersProvider = FutureProvider<List<FolderUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);

  return Isolate.run(() {
    final map = <String, int>{};
    for (final song in songs) {
      final dir = p.dirname(song.filePath);
      map[dir] = (map[dir] ?? 0) + 1;
    }
    return map.entries
        .map((e) => (path: e.key, name: p.basename(e.key), songCount: e.value))
        .toList()
      ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
  });
});

// --- Detail Providers ---

final albumSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, albumId) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByAlbum(AlbumId(albumId));
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final artistSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, artistId) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByArtist(ArtistId(artistId));
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final folderSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, folderPath) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByFolder(folderPath);
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final genreSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, genre) async {
  // Genre doesn't have a dedicated repository method, so we filter the in-memory list.
  final allSongs = await ref.watch(sortedSongsProvider.future);
  return allSongs.where((s) => s.genreNames.contains(genre)).toList();
});
