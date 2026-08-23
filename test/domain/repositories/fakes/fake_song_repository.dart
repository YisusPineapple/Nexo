import 'package:nexo/core/error/failures.dart';
import 'package:nexo/core/utils/result.dart';
import 'package:nexo/domain/entities/song.dart';
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

  @override
  Future<Result<List<Song>, Failure>> getAllSongs() async {
    return Ok(List.unmodifiable(_songs));
  }

  @override
  Future<Result<Song, Failure>> getSongById(SongId id) async {
    for (final song in _songs) {
      if (song.id == id) return Ok(song);
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
  Future<Result<List<Song>, Failure>> searchSongs(String query) async {
    final normalized = query.toLowerCase();
    return Ok(
      _songs.where((s) => s.title.toLowerCase().contains(normalized)).toList(),
    );
  }

  @override
  Future<Result<void, Failure>> updateLyricOffset(SongId id, int offsetMs) async {
    final index = _songs.indexWhere((s) => s.id == id);
    if (index != -1) {
      _songs[index] = _songs[index].copyWith(lyricOffsetMs: offsetMs);
      return const Ok(null);
    }
    return Err(NotFoundFailure('No song found with id "${id.value}".'));
  }
}