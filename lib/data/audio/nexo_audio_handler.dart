import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/song.dart';

class NexoAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  NexoAudioHandler() {
    _init();
  }

  // --- Players ---
  final ja.AudioPlayer _playerA = ja.AudioPlayer();
  final ja.AudioPlayer _playerB = ja.AudioPlayer();
  bool _isPlayerAActive = true;

  // --- Queue ---
  List<Song> _queue = [];
  int _currentIndex = 0;

  // --- Settings ---
  double _currentSpeed = 1.0;
  double _currentPitch = 1.0;
  CrossfadeConfig _config = CrossfadeConfig.disabled;

  // --- Crossfade State ---
  Timer? _crossfadeTimer;
  bool _isTransitioning = false;
  double _crossfadeProgress = 0.0;
  double _frozenProgress = 0.0;
  double _gainA = 1.0;
  double _gainB = 1.0;

  // --- Callbacks for Presentation ---
  void Function(int newIndex)? onQueueAdvanced;
  VoidCallback? onQueueEnded;

  // --- Internal Getters ---
  ja.AudioPlayer get _activePlayer => _isPlayerAActive ? _playerA : _playerB;
  ja.AudioPlayer get _inactivePlayer => _isPlayerAActive ? _playerB : _playerA;
  ja.AudioPlayer get player => _activePlayer; // For external position queries

  // --- Streams ---
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
  StreamSubscription<void>? _completedSub;

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<void> get completedStream => _completedController.stream;

  // --- Init ---
  void _init() {
    _activePlayer.playbackEventStream.listen(_broadcastState);
    _activePlayer.playingStream
        .listen((_) => _broadcastState(_activePlayer.playbackEvent));

    // Natural completion triggers internal advance
    _playerA.processingStateStream.listen((state) {
      if (state == ja.ProcessingState.completed) _onNaturalEnd();
    });
    _playerB.processingStateStream.listen((state) {
      if (state == ja.ProcessingState.completed) _onNaturalEnd();
    });

    _switchActivePlayer();
  }

  void _broadcastState(ja.PlaybackEvent event) {
    final playing = _activePlayer.playing;
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
      }[_activePlayer.processingState]!,
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
    _completedSub?.cancel();

    _positionSub = _activePlayer.positionStream.listen(_positionController.add);
    _durationSub = _activePlayer.durationStream.listen(_durationController.add);
    _playingSub = _activePlayer.playingStream.listen(_playingController.add);
    _completedSub = _activePlayer.processingStateStream
        .where((state) => state == ja.ProcessingState.completed)
        .listen((_) => _completedController.add(null));

    unawaited(_activePlayer.setSpeed(_currentSpeed));
    unawaited(_activePlayer.setPitch(_currentPitch));
  }

  // --- Core Logic ---

  /// Loads a song into a player safely: waits for idle state before setting file.
  Future<void> _loadSongIntoPlayer(ja.AudioPlayer player, Song song,
      {Duration startAt = Duration.zero}) async {
    try {
      // Wait until the player is idle
      if (player.processingState != ja.ProcessingState.idle) {
        await player.stop();
        await player.processingStateStream
            .firstWhere((s) => s == ja.ProcessingState.idle);
      }

      final startTrim =
          Duration(milliseconds: song.silenceTrim.leadingSilenceMs);
      final endTrim =
          Duration(milliseconds: song.silenceTrim.trailingSilenceMs);
      final effectiveEnd = song.duration - endTrim;

      await player.setFilePath(song.filePath, initialPosition: startAt);
      if (startTrim > Duration.zero || endTrim > Duration.zero) {
        await player.setClip(start: startTrim, end: effectiveEnd);
      }

      final double targetDb = -14.0;
      final double? gainDb = song.replayGainTrackDb ?? song.replayGainAlbumDb;
      final double gainFactor =
          gainDb != null ? pow(10, (gainDb - targetDb) / 20.0).toDouble() : 1.0;
      await player.setVolume(gainFactor);

      if (identical(player, _playerA)) {
        _gainA = gainFactor;
      } else {
        _gainB = gainFactor;
      }
    } on ja.PlayerInterruptedException catch (e) {
      debugPrint('Load interrupted for ${song.title}: $e');
      rethrow; // Let the caller handle fallback
    } catch (e) {
      debugPrint('Error loading song ${song.title}: $e');
      rethrow;
    }
  }

  Future<void> syncQueue(List<Song> songs, int currentIndex) async {
    _abortCrossfade();
    _queue = songs;
    _currentIndex = currentIndex;
    if (_queue.isEmpty) return;

    // Load current song into Player A
    await _loadSongIntoPlayer(_playerA, _queue[_currentIndex]);
    _isPlayerAActive = true;
    _switchActivePlayer();

    // Preload next song into Player B if available
    if (_currentIndex + 1 < _queue.length) {
      await _loadSongIntoPlayer(_playerB, _queue[_currentIndex + 1]);
      await _playerB.pause();
      await _playerB.setVolume(0.0);
    } else {
      await _playerB.stop();
    }

    final items = _queue
        .map((song) => MediaItem(
              id: song.id.value,
              title: song.title,
              artist: song.trackArtistId.value,
              album: song.albumId?.value,
              duration: song.duration,
              artUri: song.coverArtPath != null
                  ? Uri.file(song.coverArtPath!)
                  : null,
            ))
        .toList();
    await updateQueue(items);
    mediaItem.add(items[_currentIndex]);
    await _activePlayer.play();
  }

  Future<void> loadDirectly(Song song,
      {Duration startAt = Duration.zero}) async {
    _abortCrossfade();
    _queue = [song];
    _currentIndex = 0;
    await _loadSongIntoPlayer(_playerA, song, startAt: startAt);
    _isPlayerAActive = true;
    _switchActivePlayer();
    await _playerB.stop();
    await updateQueue([
      MediaItem(
        id: song.id.value,
        title: song.title,
        artist: song.trackArtistId.value,
        album: song.albumId?.value,
        duration: song.duration,
        artUri: song.coverArtPath != null ? Uri.file(song.coverArtPath!) : null,
      )
    ]);
    mediaItem.add(MediaItem(
      id: song.id.value,
      title: song.title,
      artist: song.trackArtistId.value,
      album: song.albumId?.value,
      duration: song.duration,
      artUri: song.coverArtPath != null ? Uri.file(song.coverArtPath!) : null,
    ));
  }

  // --- Advance Logic ---

  void _onNaturalEnd() {
    _autoAdvance();
  }

  void _autoAdvance() {
    if (_config.mode == CrossfadeMode.disabled) {
      _instantSkip();
      return;
    }
    if (_currentIndex + 1 >= _queue.length) {
      onQueueEnded?.call();
      return;
    }
    // Ensure the inactive player has the next song loaded.
    if (_inactivePlayer.processingState == ja.ProcessingState.idle) {
      // Try loading, if fails, fallback to instant skip.
      _loadSongIntoPlayer(_inactivePlayer, _queue[_currentIndex + 1])
          .then((_) => _startCrossfade())
          .catchError((_) => _instantSkip());
      return;
    }
    _startCrossfade();
  }

  void _instantSkip() {
    if (_currentIndex + 1 >= _queue.length) {
      onQueueEnded?.call();
      return;
    }
    _currentIndex++;
    // Load next song into active player
    _loadSongIntoPlayer(_activePlayer, _queue[_currentIndex]).then((_) {
      _switchActivePlayer();
      _activePlayer.play();
      onQueueAdvanced?.call(_currentIndex);
    }).catchError((_) {
      // If loading fails, recursively skip to next.
      _instantSkip();
    });
  }

  Future<void> advanceToNext() async {
    _abortCrossfade();
    _instantSkip();
  }

  // --- Crossfade Engine ---

  Duration _calculateAutoDuration(Song outSong, Song inSong) {
    final totalSilence = outSong.silenceTrim.trailingSilenceMs +
        inSong.silenceTrim.leadingSilenceMs;
    if (totalSilence > 4000) return const Duration(seconds: 2);
    if (totalSilence < 500) return const Duration(seconds: 8);
    final ratio = 1 - ((totalSilence - 500) / 3500);
    return Duration(milliseconds: (2000 + (6000 * ratio)).round());
  }

  void _startCrossfade() {
    if (_isTransitioning) {
      return;
    }
    if (_inactivePlayer.processingState == ja.ProcessingState.idle) {
      return; // Not ready
    }

    final Duration duration;
    if (_config.isAutoDuration &&
        (_config.mode == CrossfadeMode.autoMix ||
            _config.mode == CrossfadeMode.intelligent)) {
      duration = _calculateAutoDuration(
          _queue[_currentIndex], _queue[_currentIndex + 1]);
    } else {
      duration = _config.duration;
    }

    if (duration == Duration.zero) {
      _completeCrossfade();
      return;
    }

    _isTransitioning = true;
    _crossfadeProgress = 0.0;
    _frozenProgress = 0.0;

    // Start playing the inactive player (it's currently paused and volume 0)
    unawaited(_inactivePlayer.play());

    const tickRate = Duration(milliseconds: 50);
    final totalTicks = duration.inMilliseconds / tickRate.inMilliseconds;

    _crossfadeTimer = Timer.periodic(tickRate, (timer) {
      if (!_activePlayer.playing && !_inactivePlayer.playing) {
        // Both paused: freeze progress
        _frozenProgress = _crossfadeProgress;
        timer.cancel();
        _isTransitioning = false;
        return;
      }

      _crossfadeProgress += (1 / totalTicks);
      if (_crossfadeProgress >= 1.0) {
        _crossfadeProgress = 1.0;
        timer.cancel();
        _completeCrossfade();
        return;
      }

      final double angle = _crossfadeProgress * (pi / 2);
      final double volA = cos(angle) * _gainA;
      final double volB = sin(angle) * _gainB;
      unawaited(_playerA.setVolume(volA));
      unawaited(_playerB.setVolume(volB));
    });
  }

  void _completeCrossfade() {
    _isTransitioning = false;
    _frozenProgress = 0.0;
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;

    unawaited(_activePlayer.setVolume(0.0));
    unawaited(_inactivePlayer.setVolume(_gainB));

    _isPlayerAActive = !_isPlayerAActive;
    _currentIndex++;
    _switchActivePlayer();

    onQueueAdvanced?.call(_currentIndex);

    // Preload the next-next song into the now inactive player
    if (_currentIndex + 1 < _queue.length) {
      unawaited(_loadSongIntoPlayer(_inactivePlayer, _queue[_currentIndex + 1])
          .then((_) => _inactivePlayer.pause())
          .catchError((_) {}));
      unawaited(_inactivePlayer.setVolume(0.0));
    } else {
      unawaited(_inactivePlayer.stop());
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
    unawaited(_playerA.setVolume(_isPlayerAActive ? _gainA : 0.0));
    unawaited(_playerB.setVolume(_isPlayerAActive ? 0.0 : _gainB));
  }

  // --- OS Controls ---

  @override
  Future<void> play() async {
    if (_frozenProgress > 0.0) {
      // Resume crossfade from frozen progress
      _crossfadeProgress = _frozenProgress;
      _frozenProgress = 0.0;
      _isTransitioning = true;
      _startCrossfade();
      return;
    }
    // Resume both players if they are paused
    if (_isTransitioning) {
      unawaited(_activePlayer.play());
      unawaited(_inactivePlayer.play());
    } else {
      await _activePlayer.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_isTransitioning) {
      // Pause both players and freeze progress
      await _activePlayer.pause();
      await _inactivePlayer.pause();
      _frozenProgress = _crossfadeProgress;
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

  @override
  Future<void> skipToPrevious() async {
    _abortCrossfade();
    if (_currentIndex > 0) {
      _currentIndex--;
      await _loadSongIntoPlayer(_activePlayer, _queue[_currentIndex]);
      _switchActivePlayer();
      await _activePlayer.play();
      onQueueAdvanced?.call(_currentIndex);
    } else {
      await _activePlayer.seek(Duration.zero);
    }
  }

  @override
  Future<void> stop() async {
    _abortCrossfade();
    await _activePlayer.stop();
    await _inactivePlayer.stop();
    await super.stop();
  }

  void setCrossfadeConfig(CrossfadeConfig config) {
    _config = config;
    if (_isTransitioning) {
      _abortCrossfade();
      _startCrossfade();
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
    await _positionController.close();
    await _durationController.close();
    await _playingController.close();
    await _completedController.close();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playingSub?.cancel();
    await _completedSub?.cancel();
    await _playerA.dispose();
    await _playerB.dispose();
  }
}
