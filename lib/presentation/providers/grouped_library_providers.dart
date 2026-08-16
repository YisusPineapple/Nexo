import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/song.dart';
import '../../domain/value_objects/album_id.dart';
import '../../domain/value_objects/artist_id.dart';
import '../utils/artist_splitter.dart';
import 'library_providers.dart';
import 'repository_providers.dart';

enum AlbumSortOption { name, artist, songCount }
enum ArtistSortOption { name, songCount, albumCount }

final albumSortOptionProvider = StateProvider<AlbumSortOption>((ref) => AlbumSortOption.name);
final artistSortOptionProvider = StateProvider<ArtistSortOption>((ref) => ArtistSortOption.name);

typedef AlbumUiModel = ({String id, String name, String artist, String? coverArtPath, int songCount});
typedef ArtistUiModel = ({String name, int songCount, int albumCount, int collaborationCount, String? coverArtPath});
typedef GenreUiModel = ({String name, int songCount});
typedef FolderUiModel = ({String path, String name, int songCount});

final albumsProvider = FutureProvider<List<AlbumUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);
  final sortOption = ref.watch(albumSortOptionProvider);
  
  return Isolate.run(() {
    final map = <String, AlbumUiModel>{};
    for (final song in songs) {
      final albumId = song.albumId?.value;
      if (albumId == null) continue;
      if (!map.containsKey(albumId)) {
        map[albumId] = (id: albumId, name: albumId, artist: song.albumArtistId?.value ?? song.trackArtistId.value, coverArtPath: song.coverArtPath, songCount: 1);
      } else {
        final existing = map[albumId]!;
        map[albumId] = (id: existing.id, name: existing.name, artist: existing.artist, coverArtPath: existing.coverArtPath ?? song.coverArtPath, songCount: existing.songCount + 1);
      }
    }
    final list = map.values.toList();
    list.sort((a, b) {
      switch (sortOption) {
        case AlbumSortOption.name: return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case AlbumSortOption.artist: return a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
        case AlbumSortOption.songCount: return b.songCount.compareTo(a.songCount);
      }
    });
    return list;
  });
});

final artistsProvider = FutureProvider<List<ArtistUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);
  final sortOption = ref.watch(artistSortOptionProvider);
  
  return Isolate.run(() {
    final map = <String, ({String displayName, int songCount, Set<String> albums, int collabCount, String? coverArtPath})>{};
    for (final song in songs) {
      final individuals = splitArtists(song.trackArtistId.value);
      final isCollab = individuals.length > 1;
      for (final artist in individuals) {
        final key = normalizeArtist(artist);
        if (key.isEmpty) continue;
        if (!map.containsKey(key)) {
          map[key] = (displayName: artist, songCount: 0, albums: <String>{}, collabCount: 0, coverArtPath: null);
        }
        final entry = map[key]!;
        final updatedAlbums = entry.albums.toSet();
        if (song.albumId != null) updatedAlbums.add(song.albumId!.value);
        map[key] = (displayName: entry.displayName, songCount: entry.songCount + 1, albums: updatedAlbums, collabCount: entry.collabCount + (isCollab ? 1 : 0), coverArtPath: entry.coverArtPath ?? song.coverArtPath);
      }
    }
    final list = map.values.map((e) => (name: e.displayName, songCount: e.songCount, albumCount: e.albums.where((a) => a.isNotEmpty).length, collaborationCount: e.collabCount, coverArtPath: e.coverArtPath)).toList();
    list.sort((a, b) {
      switch (sortOption) {
        case ArtistSortOption.name: return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ArtistSortOption.songCount: return b.songCount.compareTo(a.songCount);
        case ArtistSortOption.albumCount: return b.albumCount.compareTo(a.albumCount);
      }
    });
    return list;
  });
});

final multiArtistSongsProvider = FutureProvider.family<List<Song>, String>((ref, artistName) async {
  final allSongs = await ref.watch(sortedSongsProvider.future);
  final target = normalizeArtist(artistName);
  return Isolate.run(() {
    return allSongs.where((song) {
      final artists = splitArtists(song.trackArtistId.value);
      return artists.any((a) => normalizeArtist(a) == target);
    }).toList();
  });
});

final genresProvider = FutureProvider<List<GenreUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);
  return Isolate.run(() {
    final map = <String, int>{};
    for (final song in songs) {
      for (final genre in song.genreNames) {
        map[genre] = (map[genre] ?? 0) + 1;
      }
    }
    return map.entries.map((e) => (name: e.key, songCount: e.value)).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });
});

final foldersProvider = FutureProvider<List<FolderUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);
  return Isolate.run(() {
    final map = <String, int>{};
    for (final song in songs) {
      final dir = p.dirname(song.filePath);
      map[dir] = (map[dir] ?? 0) + 1;
    }
    return map.entries.map((e) => (path: e.key, name: p.basename(e.key), songCount: e.value)).toList()..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
  });
});

final albumSongsProvider = FutureProvider.family<List<Song>, String>((ref, albumId) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByAlbum(AlbumId(albumId));
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final artistSongsProvider = FutureProvider.family<List<Song>, String>((ref, artistId) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByArtist(ArtistId(artistId));
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final folderSongsProvider = FutureProvider.family<List<Song>, String>((ref, folderPath) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByFolder(folderPath);
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final genreSongsProvider = FutureProvider.family<List<Song>, String>((ref, genre) async {
  final allSongs = await ref.watch(sortedSongsProvider.future);
  return allSongs.where((s) => s.genreNames.contains(genre)).toList();
});