import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/playback_speed.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/audio_player_repository.dart';
import 'nexo_audio_handler.dart';

final class AudioPlayerRepositoryImpl implements AudioPlayerRepository {
  AudioPlayerRepositoryImpl(this._handler);

  final NexoAudioHandler _handler;

  @override
  Future<Result<void, Failure>> load(
    Song song, {
    Duration startAt = Duration.zero,
  }) async {
    try {
      await _handler.loadDirectly(song, startAt: startAt);
      return const Ok(null);
    } on ja.PlayerException catch (e) {
      return Err(PlaybackFailure(
        'Could not load "${song.filePath}": ${e.message}',
        reason: PlaybackFailureReason.decodeError,
        cause: e,
      ));
    } on ja.PlayerInterruptedException catch (e) {
      return Err(PlaybackFailure(
        'Loading "${song.filePath}" was interrupted.',
        reason: PlaybackFailureReason.engineError,
        cause: e,
      ));
    } catch (e) {
      return Err(PlaybackFailure(
        'Unexpected error loading "${song.filePath}".',
        reason: PlaybackFailureReason.engineError,
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> resume() async {
    try {
      unawaited(_handler.play());
      return const Ok(null);
    } catch (e) {
      return Err(PlaybackFailure(
        'Engine failed to resume playback.',
        reason: PlaybackFailureReason.engineError,
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> pause() async {
    try {
      await _handler.pause();
      return const Ok(null);
    } catch (e) {
      return Err(PlaybackFailure(
        'Engine failed to pause playback.',
        reason: PlaybackFailureReason.engineError,
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> stop() async {
    try {
      await _handler.stop();
      return const Ok(null);
    } catch (e) {
      return Err(PlaybackFailure(
        'Engine failed to stop playback.',
        reason: PlaybackFailureReason.engineError,
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> seekTo(Duration position) async {
    try {
      await _handler.seek(position);
      return const Ok(null);
    } catch (e) {
      return Err(PlaybackFailure(
        'Engine failed to seek to $position.',
        reason: PlaybackFailureReason.engineError,
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> setSpeed(PlaybackSpeed speed) async {
    try {
      await _handler.setSpeed(speed.multiplier);
      await _handler.setPitch(
        speed.pitchCorrectionEnabled ? 1.0 : speed.multiplier,
      );
      return const Ok(null);
    } catch (e) {
      return Err(PlaybackFailure(
        'Engine failed to apply speed ${speed.multiplier}x.',
        reason: PlaybackFailureReason.engineError,
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> setCrossfade(CrossfadeConfig config) async {
    _handler.setCrossfadeConfig(config);
    return const Ok(null);
  }

  @override
  Future<Result<Duration, Failure>> getCurrentPosition() async {
    return Ok(_handler.player.position);
  }

  @override
  Future<Result<void, Failure>> updateQueue(
    List<Song> songs, {
    required int currentIndex,
    required RepeatMode repeatMode,
  }) async {
    try {
      await _handler.syncQueue(songs, currentIndex, repeatMode);
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to sync queue to OS.', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> advanceToNext() async {
    try {
      await _handler.advanceToNext();
      return const Ok(null);
    } catch (e) {
      return Err(
          UnexpectedFailure('Failed to advance to next song.', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> advanceToPrevious() async {
    try {
      await _handler.advanceToPrevious();
      return const Ok(null);
    } catch (e) {
      return Err(
          UnexpectedFailure('Failed to advance to previous song.', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setSleepTimer(Duration? duration) async {
    _handler.setSleepTimer(duration);
    return const Ok(null);
  }

  @override
  Stream<Duration> get positionStream => _handler.positionStream;
  @override
  Stream<Duration?> get durationStream => _handler.durationStream;
  @override
  Stream<bool> get playingStream => _handler.playingStream;
  @override
  Stream<void> get completedStream => _handler.completedStream;
  @override
  Stream<Duration?> get sleepTimerStream => _handler.sleepTimerStream;

  Future<void> dispose() async {
    await _handler.stop();
    await _handler.dispose();
  }
}
