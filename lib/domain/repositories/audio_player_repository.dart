import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/crossfade_config.dart';
import '../entities/playback_speed.dart';
import '../entities/song.dart';

abstract interface class AudioPlayerRepository {
  Future<Result<void, Failure>> load(Song song, {Duration startAt = Duration.zero});
  Future<Result<void, Failure>> resume();
  Future<Result<void, Failure>> pause();
  Future<Result<void, Failure>> seekTo(Duration position);
  Future<Result<void, Failure>> setSpeed(PlaybackSpeed speed);
  Future<Result<void, Failure>> setCrossfade(CrossfadeConfig config);
  Future<Result<Duration, Failure>> getCurrentPosition();
  Future<Result<void, Failure>> updateQueue(List<Song> songs, {required int currentIndex});

  /// NEW: Tell the engine to advance to the next song in its internal queue,
  /// applying crossfade if enabled, without external interference.
  Future<Result<void, Failure>> advanceToNext();

  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;
  Stream<void> get completedStream;
}