import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/playback_speed.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/audio_player_repository.dart';
import 'nexo_audio_handler.dart';

/// Real [AudioPlayerRepository] backed by [NexoAudioHandler] (which wraps
/// just_audio and audio_service).
final class AudioPlayerRepositoryImpl implements AudioPlayerRepository {
  AudioPlayerRepositoryImpl(this._handler);

  final NexoAudioHandler _handler;

  CrossfadeConfig _crossfadeConfig = CrossfadeConfig.disabled;

  CrossfadeConfig get crossfadeConfig => _crossfadeConfig;

  @override
  Future<Result<void, Failure>> load(
    Song song, {
    Duration startAt = Duration.zero,
  }) async {
    try {
      await _handler.player.setFilePath(song.filePath, initialPosition: startAt);
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
      await _handler.player.setSpeed(speed.multiplier);
      await _handler.player.setPitch(
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
    _crossfadeConfig = config;
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
  }) async {
    try {
      await _handler.syncQueue(songs, currentIndex);
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to sync queue to OS.', cause: e));
    }
  }

  @override
  Stream<Duration> get positionStream => _handler.player.positionStream;

  @override
  Stream<Duration?> get durationStream => _handler.player.durationStream;

  @override
  Stream<bool> get playingStream => _handler.player.playingStream;

  @override
  Stream<void> get completedStream => _handler.player.processingStateStream
      .where((state) => state == ja.ProcessingState.completed)
      .map((_) {});

  Future<void> dispose() async {
    await _handler.stop();
    await _handler.player.dispose();
  }
}