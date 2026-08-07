import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../domain/entities/song.dart';

/// The bridge between the OS media controls (audio_service) and the actual
/// audio engine (just_audio). 
/// 
/// This class OWNS the [ja.AudioPlayer] instance. It listens to the player's
/// state and broadcasts it to the OS, and it receives commands from the OS
/// (like a Bluetooth headphone button press) and passes them to the player.
class NexoAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  NexoAudioHandler() {
    _init();
  }

  final ja.AudioPlayer player = ja.AudioPlayer();

  void _init() {
    // Broadcast playback state changes to the OS
    player.playbackEventStream.listen(_broadcastState);
    
    // Also broadcast when play/pause state changes
    player.playingStream.listen((_) {
      _broadcastState(player.playbackEvent);
    });
  }

  void _broadcastState(ja.PlaybackEvent event) {
    final playing = player.playing;
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
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ja.ProcessingState.idle: AudioProcessingState.idle,
        ja.ProcessingState.loading: AudioProcessingState.loading,
        ja.ProcessingState.buffering: AudioProcessingState.buffering,
        ja.ProcessingState.ready: AudioProcessingState.ready,
        ja.ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    return super.stop();
  }

  /// Custom method called by our [AudioPlayerRepositoryImpl] to sync
  /// the Domain's PlaybackQueue into audio_service's MediaItem queue.
  Future<void> syncQueue(List<Song> songs, int currentIndex) async {
    final items = songs.map((song) {
      return MediaItem(
        id: song.id.value,
        title: song.title,
        artist: song.trackArtistId.value,
        album: song.albumId?.value,
        duration: song.duration,
        // audio_service requires a URI. We use the local file URI.
        artUri: song.coverArtPath != null ? Uri.file(song.coverArtPath!) : null,
      );
    }).toList();

    await updateQueue(items);
    
    if (currentIndex >= 0 && currentIndex < items.length) {
      mediaItem.add(items[currentIndex]);
    } else {
      mediaItem.add(null);
    }
  }
}