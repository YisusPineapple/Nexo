import 'dart:io';
import 'package:path/path.dart' as p;

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/lyric_line.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../../domain/value_objects/song_id.dart';
import '../../domain/repositories/song_repository.dart';
import '../sources/lyrics_parser.dart';

/// Implementation that looks for a `.lrc` file in the same directory
/// as the audio file, with the same base name.
class LyricsRepositoryImpl implements LyricsRepository {
  LyricsRepositoryImpl(this._songRepository);

  final SongRepository _songRepository; // needed to get file path from SongId

  @override
  Future<Result<List<LyricLine>, Failure>> getLyrics(SongId songId) async {
    // 1. Fetch the song to obtain its file path.
    final songResult = await _songRepository.getSongById(songId);
    if (songResult.isErr) {
      return Err(songResult.when(ok: (_) => throw Exception(), err: (e) => e));
    }
    final song = songResult.valueOrNull!;
    final audioPath = song.filePath;

    // 2. Build the expected .lrc file path.
    final dir = p.dirname(audioPath);
    final basename = p.basenameWithoutExtension(audioPath);
    final lrcPath = p.join(dir, '$basename.lrc');

    final lrcFile = File(lrcPath);
    if (!await lrcFile.exists()) {
      // No lyrics file – return empty list (not an error).
      return const Ok([]);
    }

    try {
      final content = await lrcFile.readAsString();
      final lines = LyricsParser.parse(content);
      return Ok(lines);
    } catch (e) {
      return Err(UnexpectedFailure(
        'Failed to parse LRC file: $e',
        cause: e,
      ));
    }
  }
}
