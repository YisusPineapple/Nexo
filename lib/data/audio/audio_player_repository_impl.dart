import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/playback_speed.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/audio_player_repository.dart';

/// Real [AudioPlayerRepository] backed by just_audio's [ja.AudioPlayer]
/// — the actual native decode/output engine.
///
/// SCOPE, deliberate (see Sub-fase 2.4's rollout notes): true
/// crossfade MIXING and the audio_service background/notification/
/// Android Auto wiring are NOT here — both need orchestration above a
/// single engine wrapper, which belongs to Presentation (Fase 3).
/// [setCrossfade] only stores the config for that future code to read.
final class AudioPlayerRepositoryImpl implements AudioPlayerRepository {
  AudioPlayerRepositoryImpl({ja.AudioPlayer? player})
      : _player = player ?? ja.AudioPlayer();

  final ja.AudioPlayer _player;

  CrossfadeConfig _crossfadeConfig = CrossfadeConfig.disabled;

  /// The config last set via [setCrossfade] — read by whatever future
  /// orchestrates track transitions (see this class's docs on why the
  /// actual mixing isn't implemented here).
  CrossfadeConfig get crossfadeConfig => _crossfadeConfig;

  @override
  Future<Result<void, Failure>> load(
    Song song, {
    Duration startAt = Duration.zero,
  }) async {
    try {
      await _player.setFilePath(song.filePath, initialPosition: startAt);
      return const Ok(null);
    } on ja.PlayerException catch (e) {
      return Err(PlaybackFailure(
        'Could not load "${song.filePath}": ${e.message}',
        reason: PlaybackFailureReason.decodeError,
        cause: e,
      ));
    } on ja.PlayerInterruptedException catch (e) {
      // Superseded by a newer load()/dispose() before this one
      // finished loading — not a decode problem with THIS file.
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
      // Deliberately NOT awaited — see this file's class docs on why
      // just_audio's play() Future only resolves when the SONG ENDS,
      // not when it starts. unawaited() satisfies analysis_options'
      // own unawaited_futures rule explicitly, rather than silently
      // ignoring it.
      unawaited(_player.play());
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
      await _player.pause();
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
      await _player.seek(position);
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
      await _player.setSpeed(speed.multiplier);
      // Speed and pitch are independent knobs on the native engine.
      // Leaving pitch at 1.0 is what gives "pitchCorrectionEnabled"
      // its normal-pitch behavior; matching pitch to speed is what
      // gives the classic tape/vinyl speed-change effect when pitch
      // correction is turned off.
      await _player.setPitch(
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
    return Ok(_player.position);
  }

  /// Not part of [AudioPlayerRepository] — the interface has no
  /// lifecycle method, but a real [ja.AudioPlayer] holds native
  /// resources that must be released exactly once. Whichever
  /// composition root constructs this repository owns calling this
  /// when the app shuts down.
  Future<void> dispose() => _player.dispose();
}
