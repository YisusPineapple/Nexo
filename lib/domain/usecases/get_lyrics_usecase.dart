import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/lyric_line.dart';
import '../repositories/lyrics_repository.dart';
import '../value_objects/song_id.dart';
import 'use_case.dart';

/// Use case for obtaining synchronized lyrics of a song.
final class GetLyricsUseCase implements UseCase<List<LyricLine>, SongId> {
  GetLyricsUseCase(this._repository);
  final LyricsRepository _repository;

  @override
  Future<Result<List<LyricLine>, Failure>> call(SongId params) {
    return _repository.getLyrics(params);
  }
}
