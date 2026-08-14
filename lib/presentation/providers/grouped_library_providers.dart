import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/song.dart';
import '../../domain/value_objects/album_id.dart';
import '../../domain/value_objects/artist_id.dart';
import '../utils/artist_splitter.dart';
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
  int collaborationCount,
  String? coverArtPath
});

typedef GenreUiModel = ({String name, int songCount});

typedef FolderUiModel = ({String path, String name, int songCount});

/// Groups all indexed songs by Album using a background isolate.
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

/// Groups all indexed songs by INDIVIDUAL artist.
///
/// Unlike the old implementation that grouped by the raw trackArtistId
/// string (e.g. "Daft Punk feat. Pharrell" as one entry), this splits
/// collaboration strings so "Daft Punk" and "Pharrell" each get their
/// own entry with correct song/album counts.
final artistsProvider = FutureProvider<List<ArtistUiModel>>((ref) async {
  final songs = await ref.watch(sortedSongsProvider.future);
  return Isolate.run(() {
    // Accumulator: normalizedArtist → mutable stats
    final map = <String, ({
      String displayName,
      int songCount,
      Set<String> albums,
      int collabCount,
      String? coverArtPath,
    })>{};

    for (final song in songs) {
      final individuals = splitArtists(song.trackArtistId.value);
      final isCollab = individuals.length > 1;

      for (final artist in individuals) {
        final key = normalizeArtist(artist);
        if (key.isEmpty) continue;

        if (!map.containsKey(key)) {
          map[key] = (
            displayName: artist,
            songCount: 0,
            albums: <String>{},
            collabCount: 0,
            coverArtPath: null,
          );
        }

        final entry = map[key]!;
        final updatedSongCount = entry.songCount + 1;
        final updatedCollab = entry.collabCount + (isCollab ? 1 : 0);
        final updatedAlbums = entry.albums.toSet();

        if (song.albumId != null) {
          updatedAlbums.add(song.albumId!.value);
        }
        final updatedCoverArtPath = entry.coverArtPath ?? song.coverArtPath;

        map[key] = (
          displayName: entry.displayName,
          songCount: updatedSongCount,
          albums: updatedAlbums,
          collabCount: updatedCollab,
          coverArtPath: updatedCoverArtPath,
        );
      }
    }

    return map.entries
        .map((e) => (
              name: e.value.displayName,
              songCount: e.value.songCount,
              albumCount: e.value.albums.where((a) => a.isNotEmpty).length,
              collaborationCount: e.value.collabCount,
              coverArtPath: e.value.coverArtPath,
            ))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });
});

/// Returns all songs where [artistName] appears (as main artist OR
/// collaborator). Uses in-memory filtering via Isolate to avoid
/// modifying the Data layer's exact-match query.
///
/// UX rationale: tapping "Pharrell" in ArtistsScreen must show
/// "Get Lucky" even though the raw tag is "Daft Punk feat. Pharrell".
final multiArtistSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, artistName) async {
  final allSongs = await ref.watch(sortedSongsProvider.future);
  final target = normalizeArtist(artistName);

  return Isolate.run(() {
    return allSongs.where((song) {
      final artists = splitArtists(song.trackArtistId.value);
      return artists.any((a) => normalizeArtist(a) == target);
    }).toList();
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

/// Kept for backward compatibility; prefer [multiArtistSongsProvider]
/// for new UI code.
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
  final allSongs = await ref.watch(sortedSongsProvider.future);
  return allSongs.where((s) => s.genreNames.contains(genre)).toList();
});