import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/lyric_line.dart';
import '../value_objects/song_id.dart';

/// Contract for loading synchronized lyrics.
abstract interface class LyricsRepository {
  /// Returns a list of [LyricLine] for the given song, or an empty list
  /// if no lyrics are available.
  ///
  /// The implementation must be lightweight and never perform heavy
  /// processing (e.g. no audio analysis). Only file I/O and text parsing.
  Future<Result<List<LyricLine>, Failure>> getLyrics(SongId songId);
}
