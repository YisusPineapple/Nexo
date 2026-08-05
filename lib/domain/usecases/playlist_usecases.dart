import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';
import '../repositories/song_repository.dart';
import '../value_objects/playlist_id.dart';
import '../value_objects/song_id.dart';
import 'use_case.dart';

final class CreatePlaylistUseCase implements UseCase<void, String> {
  CreatePlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(String name) async {
    final id = PlaylistId(DateTime.now().millisecondsSinceEpoch.toString());
    final playlistResult = Playlist.create(
      id: id,
      name: name,
      dateCreated: DateTime.now(),
    );

    return playlistResult.asyncAndThen((playlist) => _repository.savePlaylist(playlist));
  }
}

final class DeletePlaylistUseCase implements UseCase<void, PlaylistId> {
  DeletePlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(PlaylistId id) {
    return _repository.deletePlaylist(id);
  }
}

typedef AddSongParams = ({PlaylistId playlistId, SongId songId});

final class AddSongToPlaylistUseCase implements UseCase<void, AddSongParams> {
  AddSongToPlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(AddSongParams params) {
    return _repository.addSongToPlaylist(params.playlistId, params.songId);
  }
}

typedef RemoveSongParams = ({PlaylistId playlistId, int position});

final class RemoveSongFromPlaylistUseCase implements UseCase<void, RemoveSongParams> {
  RemoveSongFromPlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(RemoveSongParams params) {
    return _repository.removeSongFromPlaylist(params.playlistId, params.position);
  }
}

typedef RenamePlaylistParams = ({PlaylistId id, String newName});

final class RenamePlaylistUseCase implements UseCase<void, RenamePlaylistParams> {
  RenamePlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(RenamePlaylistParams params) async {
    if (params.newName.trim().isEmpty) {
      return const Err(ValidationFailure('Playlist name cannot be empty.'));
    }

    final playlistResult = await _repository.getPlaylistById(params.id);
    return playlistResult.asyncAndThen((playlist) async {
      final updated = playlist.copyWith(name: params.newName.trim());
      return _repository.savePlaylist(updated);
    });
  }
}

typedef ExportPlaylistParams = ({PlaylistId id, String exportDirectory});

final class ExportPlaylistUseCase implements UseCase<void, ExportPlaylistParams> {
  ExportPlaylistUseCase(this._repository);
  final PlaylistRepository _repository;

  @override
  Future<Result<void, Failure>> call(ExportPlaylistParams params) async {
    final playlistResult = await _repository.getPlaylistById(params.id);
    if (playlistResult.isErr) return Err(playlistResult.when(ok: (_) => throw Exception(), err: (e) => e));
    final playlist = playlistResult.valueOrNull!;

    final songsResult = await _repository.getPlaylistSongs(params.id);
    if (songsResult.isErr) return Err(songsResult.when(ok: (_) => throw Exception(), err: (e) => e));
    final songs = songsResult.valueOrNull!;

    try {
      final file = File(p.join(params.exportDirectory, '${playlist.name}.m3u8'));
      final buffer = StringBuffer();
      buffer.writeln('#EXTM3U');
      
      for (final song in songs) {
        buffer.writeln('#EXTINF:${song.duration.inSeconds},${song.trackArtistId.value} - ${song.title}');
        // Calculate relative path from the export directory to the song file
        final relativePath = p.relative(song.filePath, from: params.exportDirectory);
        buffer.writeln(relativePath);
      }
      
      await file.writeAsString(buffer.toString());
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to export playlist: $e'));
    }
  }
}

final class ImportPlaylistUseCase implements UseCase<void, String> {
  ImportPlaylistUseCase(this._playlistRepo, this._songRepo);
  final PlaylistRepository _playlistRepo;
  final SongRepository _songRepo;

  @override
  Future<Result<void, Failure>> call(String m3uFilePath) async {
    try {
      final file = File(m3uFilePath);
      if (!await file.exists()) {
        return const Err(ValidationFailure('Playlist file does not exist.'));
      }

      final lines = await file.readAsLines();
      final m3uDir = p.dirname(m3uFilePath);

      // Fetch all songs to match paths in memory (avoids changing SongRepository contract)
      final allSongsResult = await _songRepo.getAllSongs();
      if (allSongsResult.isErr) return Err(allSongsResult.when(ok: (_) => throw Exception(), err: (e) => e));
      
      final allSongs = allSongsResult.valueOrNull!;
      final pathMap = {for (final s in allSongs) s.filePath: s.id};

      final matchedSongIds = <SongId>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        // Resolve path: if it's relative, make it absolute based on the m3u file's location
        final absolutePath = p.isAbsolute(trimmed) ? trimmed : p.normalize(p.join(m3uDir, trimmed));
        
        final songId = pathMap[absolutePath];
        if (songId != null) {
          matchedSongIds.add(songId);
        }
      }

      if (matchedSongIds.isEmpty) {
        return const Err(ValidationFailure('No matching songs found in the library for this playlist.'));
      }

      final playlistName = p.basenameWithoutExtension(m3uFilePath);
      final playlistId = PlaylistId(DateTime.now().millisecondsSinceEpoch.toString());
      final playlistResult = Playlist.create(
        id: playlistId,
        name: playlistName,
        dateCreated: DateTime.now(),
      );

      if (playlistResult.isErr) return Err(playlistResult.when(ok: (_) => throw Exception(), err: (e) => e));
      final playlist = playlistResult.valueOrNull!;

      await _playlistRepo.savePlaylist(playlist);
      for (final sid in matchedSongIds) {
        await _playlistRepo.addSongToPlaylist(playlistId, sid);
      }

      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to import playlist: $e'));
    }
  }
}