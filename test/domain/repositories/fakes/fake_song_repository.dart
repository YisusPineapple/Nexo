import 'dart:async';

import 'package:nexo/core/error/failures.dart';
import 'package:nexo/core/utils/result.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/entities/song_sort_option.dart';
import 'package:nexo/domain/repositories/song_repository.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

class FakeSongRepository implements SongRepository {
  FakeSongRepository({List<Song> initialSongs = const []})
      : _songs = List.of(initialSongs);

  final List<Song> _songs;
  bool failIndexing = false;
  int indexDirectoriesCallCount = 0;

  final StreamController<void> _coversUpdatedController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get coversUpdatedStream => _coversUpdatedController.stream;

  @override
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    indexDirectoriesCallCount++;
    if (failIndexing) {
      return const Err(UnexpectedFailure('Fake indexing failure.'));
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> refresh({
    void Function(int current, int total)? onProgress,
  }) async {
    if (failIndexing) {
      return const Err(UnexpectedFailure('Fake refresh failure.'));
    }
    return const Ok(null);
  }

  int _compare(Song a, Song b, SongSortOption option, bool isAscending) {
    int res;
    switch (option) {
      case SongSortOption.title:
        res = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        break;
      case SongSortOption.artist:
        res = a.trackArtistId.value
            .toLowerCase()
            .compareTo(b.trackArtistId.value.toLowerCase());
        break;
      case SongSortOption.album:
        res = (a.albumId?.value ?? '')
            .toLowerCase()
            .compareTo((b.albumId?.value ?? '').toLowerCase());
        break;
      case SongSortOption.year:
        res = (a.year ?? 0).compareTo(b.year ?? 0);
        break;
      case SongSortOption.duration:
        res = a.duration.compareTo(b.duration);
        break;
      case SongSortOption.dateAdded:
        res = a.dateAddedUtc.compareTo(b.dateAddedUtc);
        break;
    }
    return isAscending ? res : -res;
  }

  @override
  Future<Result<List<Song>, Failure>> getAllSongs({
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  }) async {
    final sorted = List<Song>.of(_songs)
      ..sort((a, b) => _compare(a, b, sortOption, isAscending));
    return Ok(List.unmodifiable(sorted));
  }

  @override
  Future<Result<Song, Failure>> getSongById(SongId id) async {
    for (final song in _songs) {
      if (song.id == id) {
        return Ok(song);
      }
    }
    return Err(NotFoundFailure('No song found with id "${id.value}".'));
  }

  @override
  Future<Result<List<Song>, Failure>> getSongsByArtist(
    ArtistId artistId,
  ) async {
    return Ok(_songs.where((s) => s.trackArtistId == artistId).toList());
  }

  @override
  Future<Result<List<Song>, Failure>> getSongsByAlbum(AlbumId albumId) async {
    return Ok(_songs.where((s) => s.albumId == albumId).toList());
  }

  @override
  Future<Result<List<Song>, Failure>> getSongsByFolder(
    String folderPath,
  ) async {
    return Ok(
      _songs.where((s) => s.filePath.startsWith(folderPath)).toList(),
    );
  }

  @override
  Future<Result<List<Song>, Failure>> searchSongs(
    String query, {
    SongSortOption sortOption = SongSortOption.title,
    bool isAscending = true,
  }) async {
    final normalized = query.toLowerCase();
    final filtered = _songs
        .where((s) => s.title.toLowerCase().contains(normalized))
        .toList();
    filtered.sort((a, b) => _compare(a, b, sortOption, isAscending));
    return Ok(filtered);
  }

  @override
  Future<Result<List<String>, Failure>> searchArtists(String query) async {
    final normalized = query.toLowerCase();
    // Emulate SQLite FTS5: find matching songs and extract their unique artists
    final matchingSongs = _songs.where((s) =>
        s.trackArtistId.value.toLowerCase().contains(normalized) ||
        s.title.toLowerCase().contains(normalized) ||
        (s.albumId?.value ?? '').toLowerCase().contains(normalized));

    final artists =
        matchingSongs.map((s) => s.trackArtistId.value).toSet().toList();
    return Ok(artists);
  }

  @override
  Future<Result<List<String>, Failure>> searchAlbums(String query) async {
    final normalized = query.toLowerCase();
    // Emulate SQLite FTS5: find matching songs and extract their unique albums
    final matchingSongs = _songs.where((s) =>
        (s.albumId?.value ?? '').toLowerCase().contains(normalized) ||
        s.title.toLowerCase().contains(normalized) ||
        s.trackArtistId.value.toLowerCase().contains(normalized));

    final albums = matchingSongs
        .where((s) => s.albumId != null)
        .map((s) => s.albumId!.value)
        .toSet()
        .toList();
    return Ok(albums);
  }

  @override
  Future<Result<void, Failure>> updateLyricOffset(
      SongId id, int offsetMs) async {
    final index = _songs.indexWhere((s) => s.id == id);
    if (index != -1) {
      _songs[index] = _songs[index].copyWith(lyricOffsetMs: offsetMs);
      return const Ok(null);
    }
    return Err(NotFoundFailure('No song found with id "${id.value}".'));
  }
}
