import 'package:nexo/core/error/failures.dart';
import 'package:nexo/core/utils/result.dart';
import 'package:nexo/domain/entities/crossfade_config.dart';
import 'package:nexo/domain/entities/playback_speed.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/repositories/audio_player_repository.dart';

/// In-memory stand-in for [AudioPlayerRepository]. Records the calls
/// it receives so tests can assert on engine interactions (e.g. "did
/// skipNext actually tell the engine to load the new song") without a
/// real native audio backend.
class FakeAudioPlayerRepository implements AudioPlayerRepository {
  Song? loadedSong;
  Duration? loadedAt;
  bool isResumed = false;
  bool isPaused = false;
  Duration? seekedTo;
  PlaybackSpeed? appliedSpeed;
  CrossfadeConfig? appliedCrossfade;

  /// Test hook: when set, every method fails with this.
  Failure? failWith;

  @override
  Future<Result<void, Failure>> load(
    Song song, {
    Duration startAt = Duration.zero,
  }) async {
    if (failWith != null) return Err(failWith!);
    loadedSong = song;
    loadedAt = startAt;
    isResumed = false;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> resume() async {
    if (failWith != null) return Err(failWith!);
    isResumed = true;
    isPaused = false;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> pause() async {
    if (failWith != null) return Err(failWith!);
    isPaused = true;
    isResumed = false;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> seekTo(Duration position) async {
    if (failWith != null) return Err(failWith!);
    seekedTo = position;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> setSpeed(PlaybackSpeed speed) async {
    if (failWith != null) return Err(failWith!);
    appliedSpeed = speed;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> setCrossfade(CrossfadeConfig config) async {
    if (failWith != null) return Err(failWith!);
    appliedCrossfade = config;
    return const Ok(null);
  }

  @override
  Future<Result<Duration, Failure>> getCurrentPosition() async {
    if (failWith != null) return Err(failWith!);
    return Ok(loadedAt ?? Duration.zero);
  }

  @override
  Stream<Duration> get positionStream => Stream.value(Duration.zero);

  @override
  Stream<Duration?> get durationStream => Stream.value(Duration.zero);

  @override
  Stream<bool> get playingStream => Stream.value(isResumed);

  @override
  Stream<void> get completedStream => const Stream.empty();
}