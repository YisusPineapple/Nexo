import 'package:nexo/core/error/failures.dart';
import 'package:nexo/core/utils/result.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/repositories/song_repository.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

/// In-memory stand-in for [SongRepository], used ONLY to prove the
/// contract is implementable and to drive it through Result's
/// happy/error paths. Deliberately lives beside the contract it
/// exercises rather than in a shared test-utils folder, so it doesn't
/// quietly become an unofficial second contract that drifts from the
/// real one.
class FakeSongRepository implements SongRepository {
  FakeSongRepository({List<Song> initialSongs = const []})
      : _songs = List.of(initialSongs);

  final List<Song> _songs;

  /// Test hook: when true, every scanning call fails — lets tests
  /// exercise the error path without needing real I/O to break.
  bool failIndexing = false;

  @override
  Future<Result<void, Failure>> indexDirectories(
    List<String> directoryPaths,
  ) async {
    if (failIndexing) {
      return const Err(UnexpectedFailure('Fake indexing failure.'));
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> refresh() async {
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
      _songs
          .where((s) => s.title.toLowerCase().contains(normalized))
          .toList(),
    );
  }
}