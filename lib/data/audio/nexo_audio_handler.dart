import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../domain/entities/song.dart';

class NexoAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  NexoAudioHandler();

  final ja.AudioPlayer _playerA = ja.AudioPlayer();
  final ja.AudioPlayer _playerB = ja.AudioPlayer();
  bool _isPlayerAActive = true;

  List<Song> _queue = [];
  int _currentIndex = 0;
  RepeatMode _repeatMode = RepeatMode.off;
  String? _currentLoadedSongId;

  double _currentSpeed = 1.0;
  double _currentPitch = 1.0;
  CrossfadeConfig _config = CrossfadeConfig.disabled;

  Timer? _crossfadeTimer;
  bool _isTransitioning = false;
  bool _isSkipping = false;
  double _crossfadeProgress = 0.0;
  double _frozenProgress = 0.0;
  double _gainA = 1.0;
  double _gainB = 1.0;

  Timer? _sleepTimer;
  final StreamController<Duration?> _sleepTimerController = StreamController<Duration?>.broadcast();

  void Function(int newIndex)? onQueueAdvanced;
  VoidCallback? onQueueEnded;

  ja.AudioPlayer get _activePlayer => _isPlayerAActive ? _playerA : _playerB;
  ja.AudioPlayer get _inactivePlayer => _isPlayerAActive ? _playerB : _playerA;
  ja.AudioPlayer get player => _activePlayer;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<void> _completedController =
      StreamController<void>.broadcast();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<ja.PlaybackEvent>? _playbackEventSub;
  StreamSubscription<bool>? _playingEventSub;

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<void> get completedStream => _completedController.stream;
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;

  void _fire(Future<dynamic> f) {
    f.catchError((e) {
      developer.log('AudioHandler async error suppressed: $e', name: 'nexo.audio');
    });
  }

  void init() {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));

    _playerA.processingStateStream.listen((state) {
      if (state == ja.ProcessingState.completed && !_isTransitioning) {
        _onNaturalEnd();
      }
    });
    _playerB.processingStateStream.listen((state) {
      if (state == ja.ProcessingState.completed && !_isTransitioning) {
        _onNaturalEnd();
      }
    });

    _switchActivePlayer();
  }

  void _broadcastState(ja.PlaybackEvent event) {
    final playing = _activePlayer.playing;
    
    if (playing) {
      developer.log('playbackState playing=true broadcast at ${DateTime.now()}', name: 'nexo.audio');
    }

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ja.ProcessingState.idle: AudioProcessingState.idle,
        ja.ProcessingState.loading: AudioProcessingState.loading,
        ja.ProcessingState.buffering: AudioProcessingState.buffering,
        ja.ProcessingState.ready: AudioProcessingState.ready,
        ja.ProcessingState.completed: AudioProcessingState.completed,
      }[_activePlayer.processingState] ?? AudioProcessingState.idle,
      playing: playing,
      updatePosition: _activePlayer.position,
      bufferedPosition: _activePlayer.bufferedPosition,
      speed: _activePlayer.speed,
      queueIndex: _currentIndex,
    ));
  }

  void _switchActivePlayer() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _playbackEventSub?.cancel();
    _playingEventSub?.cancel();

    _positionSub = _activePlayer.positionStream.listen((pos) {
      _positionController.add(pos);
      _checkCrossfadeTrigger(pos);
    });
    _durationSub = _activePlayer.durationStream.listen(_durationController.add);
    _playingSub = _activePlayer.playingStream.listen(_playingController.add);

    _playbackEventSub = _activePlayer.playbackEventStream.listen(_broadcastState);
    _playingEventSub = _activePlayer.playingStream.listen((_) => _broadcastState(_activePlayer.playbackEvent));

    _fire(_activePlayer.setSpeed(_currentSpeed));
    _fire(_activePlayer.setPitch(_currentPitch));
  }

  int? _getNextIndex() {
    if (_queue.isEmpty) return null;
    if (_repeatMode == RepeatMode.one) return _currentIndex;
    if (_currentIndex + 1 < _queue.length) return _currentIndex + 1;
    if (_repeatMode == RepeatMode.all) return 0;
    return null;
  }

  int? _getPreviousIndex() {
    if (_queue.isEmpty) return null;
    if (_repeatMode == RepeatMode.one) return _currentIndex;
    if (_currentIndex > 0) return _currentIndex - 1;
    if (_repeatMode == RepeatMode.all) return _queue.length - 1;
    return 0;
  }

  Future<void> _loadSongIntoPlayer(ja.AudioPlayer p, Song song,
      {Duration startAt = Duration.zero}) async {
    try {
      if (p.processingState != ja.ProcessingState.idle) {
        await p.stop();
      }

      final startTrim = Duration(milliseconds: song.silenceTrim.leadingSilenceMs);
      final endTrim = Duration(milliseconds: song.silenceTrim.trailingSilenceMs);
      final effectiveEnd = song.duration - endTrim;

      await p.setFilePath(song.filePath, initialPosition: startAt + startTrim);
      if (startTrim > Duration.zero || endTrim > Duration.zero) {
        await p.setClip(start: startTrim, end: effectiveEnd);
      }

      final double targetDb = -14.0;
      final double? gainDb = song.replayGainTrackDb ?? song.replayGainAlbumDb;
      final double gainFactor =
          gainDb != null ? pow(10, (gainDb - targetDb) / 20.0).toDouble() : 1.0;
      await p.setVolume(gainFactor);

      if (identical(p, _playerA)) {
        _gainA = gainFactor;
      } else {
        _gainB = gainFactor;
      }
      
      if (identical(p, _activePlayer)) {
        _currentLoadedSongId = song.id.value;
      }
    } catch (e) {
      developer.log('Error loading song ${song.title}: $e', name: 'nexo.audio');
      rethrow;
    }
  }

  // FIX: Return null if no cover art exists. audio_service handles null perfectly,
  // but fails if we pass a malformed asset URI.
  Uri? _getArtUri(String? coverArtPath) {
    if (coverArtPath != null && coverArtPath.isNotEmpty) {
      return Uri.file(coverArtPath);
    }
    return null;
  }

  Future<void> syncQueue(
      List<Song> songs, int currentIndex, RepeatMode repeatMode) async {
    _queue = songs;
    _repeatMode = repeatMode;

    if (_queue.isEmpty) {
      _abortCrossfade();
      await _activePlayer.stop();
      _currentLoadedSongId = null;
      return;
    }

    final newCurrentSong = _queue[currentIndex];
    final isSameSong = _currentLoadedSongId == newCurrentSong.id.value;

    _currentIndex = currentIndex;

    final items = _queue
        .map((song) => MediaItem(
              id: song.id.value,
              title: song.title,
              artist: song.trackArtistId.value,
              album: song.albumId?.value,
              duration: song.duration,
              artUri: _getArtUri(song.coverArtPath), 
            ))
        .toList();
    await updateQueue(items);
    mediaItem.add(items[_currentIndex]);

    if (!isSameSong) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
      ));
      
      _abortCrossfade();
      await _loadSongIntoPlayer(_playerA, newCurrentSong);
      _isPlayerAActive = true;
      _switchActivePlayer();
    }

    final nextIndex = _getNextIndex();
    if (nextIndex != null) {
      await _loadSongIntoPlayer(_inactivePlayer, _queue[nextIndex]);
      await _inactivePlayer.pause();
      await _inactivePlayer.setVolume(0.0);
    } else {
      await _inactivePlayer.stop();
    }
  }

  Future<void> loadDirectly(Song song,
      {Duration startAt = Duration.zero}) async {
    _abortCrossfade();
    _queue = [song];
    _currentIndex = 0;

    final item = MediaItem(
      id: song.id.value,
      title: song.title,
      artist: song.trackArtistId.value,
      album: song.albumId?.value,
      duration: song.duration,
      artUri: _getArtUri(song.coverArtPath),
    );
    await updateQueue([item]);
    mediaItem.add(item);

    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.loading,
    ));

    await _loadSongIntoPlayer(_playerA, song, startAt: startAt);
    _isPlayerAActive = true;
    _switchActivePlayer();
    await _playerB.stop();
  }

  void _onNaturalEnd() {
    if (!_isTransitioning) {
      _completedController.add(null);
      _instantSkip();
    }
  }

  Duration _getActualCrossfadeDuration() {
    if (_config.mode == CrossfadeMode.disabled) return Duration.zero;

    final nextIndex = _getNextIndex();
    if (nextIndex == null) return Duration.zero;
    
    final outSong = _queue[_currentIndex];
    final inSong = _queue[nextIndex];
    
    final maxAllowed = Duration(milliseconds: 
      (min(outSong.duration.inMilliseconds, inSong.duration.inMilliseconds) * 0.3).toInt()
    );

    Duration calculated;
    if (_config.isAutoDuration || _config.mode == CrossfadeMode.intelligent || _config.mode == CrossfadeMode.autoMix) {
      final totalSilence = outSong.silenceTrim.trailingSilenceMs +
          inSong.silenceTrim.leadingSilenceMs;
      if (totalSilence > 4000) {
        calculated = const Duration(seconds: 2);
      } else if (totalSilence < 500) {
        calculated = const Duration(seconds: 8);
      } else {
        final ratio = 1 - ((totalSilence - 500) / 3500);
        calculated = Duration(milliseconds: (2000 + (6000 * ratio)).round());
      }
    } else {
      calculated = _config.duration;
    }

    return calculated > maxAllowed ? maxAllowed : calculated;
  }

  void _checkCrossfadeTrigger(Duration pos) {
    if (_isTransitioning || _config.mode == CrossfadeMode.disabled) return;
    final nextIndex = _getNextIndex();
    if (nextIndex == null) return;
    final duration = _activePlayer.duration;
    if (duration == null) return;
    final crossfadeDur = _getActualCrossfadeDuration();
    if (crossfadeDur == Duration.zero) return;

    if (duration - pos <= crossfadeDur) {
      _startCrossfade(crossfadeDur);
    }
  }

  void _startCrossfade(Duration duration) {
    if (_isTransitioning ||
        _inactivePlayer.processingState == ja.ProcessingState.idle) {
      return;
    }

    _isTransitioning = true;

    if (_frozenProgress == 0.0) {
      _crossfadeProgress = 0.0;
    } else {
      _crossfadeProgress = _frozenProgress;
      _frozenProgress = 0.0;
    }

    _fire(_activePlayer.play());
    _fire(_inactivePlayer.play());

    const tickRate = Duration(milliseconds: 50);
    final totalTicks = duration.inMilliseconds / tickRate.inMilliseconds;

    _crossfadeTimer = Timer.periodic(tickRate, (timer) {
      _crossfadeProgress += (1 / totalTicks);
      if (_crossfadeProgress >= 1.0) {
        _crossfadeProgress = 1.0;
        timer.cancel();
        _completeCrossfade();
        return;
      }

      final double angle = _crossfadeProgress * (pi / 2);
      final double volA = cos(angle) * (_isPlayerAActive ? _gainA : _gainB);
      final double volB = sin(angle) * (_isPlayerAActive ? _gainB : _gainA);

      _fire(_activePlayer.setVolume(volA));
      _fire(_inactivePlayer.setVolume(volB));
    });
  }

  void _completeCrossfade() {
    _isTransitioning = false;
    _frozenProgress = 0.0;
    if (_crossfadeTimer != null) {
      _crossfadeTimer!.cancel();
      _crossfadeTimer = null;
    }

    _completedController.add(null);

    _fire(_activePlayer.stop());
    _fire(_inactivePlayer.setVolume(_isPlayerAActive ? _gainB : _gainA));

    final nextIndex = _getNextIndex();
    if (nextIndex != null) {
      _currentIndex = nextIndex;
    } else {
      _currentIndex++;
    }

    _isPlayerAActive = !_isPlayerAActive;
    _switchActivePlayer();
    _currentLoadedSongId = _queue[_currentIndex].id.value;

    if (_currentIndex < _queue.length) {
      mediaItem.add(queue.value[_currentIndex]);
    }
    onQueueAdvanced?.call(_currentIndex);

    final nextNextIndex = _getNextIndex();
    if (nextNextIndex != null) {
      _fire(_loadSongIntoPlayer(_inactivePlayer, _queue[nextNextIndex])
          .then((_) => _inactivePlayer.pause()));
      _fire(_inactivePlayer.setVolume(0.0));
    } else {
      _fire(_inactivePlayer.stop());
    }
  }

  void _abortCrossfade() {
    if (_crossfadeTimer != null) {
      _crossfadeTimer!.cancel();
      _crossfadeTimer = null;
    }
    _isTransitioning = false;
    _frozenProgress = 0.0;
    _crossfadeProgress = 0.0;
    _fire(_playerA.setVolume(_isPlayerAActive ? _gainA : 0.0));
    _fire(_playerB.setVolume(_isPlayerAActive ? 0.0 : _gainB));
  }

  Future<void> _instantSkip() async {
    final nextIndex = _getNextIndex();
    if (nextIndex == null) {
      onQueueEnded?.call();
      return;
    }
    
    _currentIndex = nextIndex;
    
    _isPlayerAActive = !_isPlayerAActive;
    _switchActivePlayer();
    _currentLoadedSongId = _queue[_currentIndex].id.value;
    
    _fire(_activePlayer.setVolume(_isPlayerAActive ? _gainA : _gainB));
    _fire(_activePlayer.play());
    
    if (_currentIndex < _queue.length) {
      mediaItem.add(queue.value[_currentIndex]);
    }
    onQueueAdvanced?.call(_currentIndex);

    final nextNextIndex = _getNextIndex();
    if (nextNextIndex != null) {
      _fire(_loadSongIntoPlayer(_inactivePlayer, _queue[nextNextIndex])
          .then((_) => _inactivePlayer.pause()));
      _fire(_inactivePlayer.setVolume(0.0));
    } else {
      _fire(_inactivePlayer.stop());
    }
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null || duration.inMinutes <= 0) {
      _sleepTimerController.add(null);
      return;
    }
    
    final endTime = DateTime.now().add(duration);
    _sleepTimerController.add(duration);
    
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = endTime.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        _sleepTimerController.add(null);
        pause(); 
      } else {
        _sleepTimerController.add(remaining);
      }
    });
  }

  @override
  Future<void> play() async {
    developer.log('play() called at ${DateTime.now()}', name: 'nexo.audio');
    
    if (_frozenProgress > 0.0) {
      final crossfadeDur = _getActualCrossfadeDuration();
      _startCrossfade(crossfadeDur);
    } else {
      _fire(_activePlayer.play());
    }
  }

  @override
  Future<void> pause() async {
    if (_isTransitioning) {
      _frozenProgress = _crossfadeProgress;
      if (_crossfadeTimer != null) {
        _crossfadeTimer!.cancel();
      }
      _isTransitioning = false;
      await _activePlayer.pause();
      await _inactivePlayer.pause();
    } else {
      await _activePlayer.pause();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    _abortCrossfade();
    await _activePlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await advanceToNext();
  }

  Future<void> advanceToNext() async {
    if (_isSkipping) return;
    _isSkipping = true;
    _abortCrossfade();
    await _instantSkip();
    _isSkipping = false;
  }

  @override
  Future<void> skipToPrevious() async {
    if (_isSkipping) return;
    _isSkipping = true;
    _abortCrossfade();

    final prevIndex = _getPreviousIndex();
    if (prevIndex != null && prevIndex != _currentIndex) {
      _currentIndex = prevIndex;
      await _loadSongIntoPlayer(_activePlayer, _queue[_currentIndex]);
      _switchActivePlayer();
      _fire(_activePlayer.play());
      if (_currentIndex < _queue.length) {
        mediaItem.add(queue.value[_currentIndex]);
      }
      onQueueAdvanced?.call(_currentIndex);
    } else {
      await _activePlayer.seek(Duration.zero);
    }
    _isSkipping = false;
  }

  @override
  Future<void> stop() async {
    _abortCrossfade();
    await _activePlayer.stop();
    await _inactivePlayer.stop();
    _currentLoadedSongId = null;
    await super.stop();
  }

  void setCrossfadeConfig(CrossfadeConfig config) {
    _config = config;
    if (_isTransitioning) {
      _abortCrossfade();
      final crossfadeDur = _getActualCrossfadeDuration();
      _startCrossfade(crossfadeDur);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    await _activePlayer.setSpeed(speed);
  }

  Future<void> setPitch(double pitch) async {
    _currentPitch = pitch;
    await _activePlayer.setPitch(pitch);
  }

  Future<void> dispose() async {
    _abortCrossfade();
    _sleepTimer?.cancel();
    await _positionController.close();
    await _durationController.close();
    await _playingController.close();
    await _completedController.close();
    await _sleepTimerController.close();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playingSub?.cancel();
    await _playbackEventSub?.cancel();
    await _playingEventSub?.cancel();
    await _playerA.dispose();
    await _playerB.dispose();
  }
}
