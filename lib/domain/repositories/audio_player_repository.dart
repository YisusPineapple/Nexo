import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/crossfade_config.dart';
import '../entities/playback_speed.dart';
import '../entities/song.dart';

/// Real-time control of the actual audio engine (just_audio +
/// audio_service in the Data layer) — as opposed to
/// [PlaybackRepository], which only persists queue/settings/session
/// STATE. Split into its own contract deliberately: persistence is
/// idempotent CRUD, while engine control is inherently stateful and
/// hardware-bound (there is exactly one engine, never "one per
/// queue") — per SOLID estricto, those are different reasons to
/// change and shouldn't share an interface.
abstract interface class AudioPlayerRepository {
  /// Loads [song] into the engine ready to play from [startAt].
  /// Deliberately does NOT start playback — pairs with [resume] so a
  /// song can be prepared without making sound yet (e.g.
  /// RestoreSessionUseCase restoring position on app launch without
  /// surprising the user with audio).
  Future<Result<void, Failure>> load(
    Song song, {
    Duration startAt = Duration.zero,
  });

  Future<Result<void, Failure>> resume();
  Future<Result<void, Failure>> pause();
  Future<Result<void, Failure>> seekTo(Duration position);
  Future<Result<void, Failure>> setSpeed(PlaybackSpeed speed);
  Future<Result<void, Failure>> setCrossfade(CrossfadeConfig config);
  Future<Result<Duration, Failure>> getCurrentPosition();

  /// Syncs the current playback queue to the underlying audio engine
  /// (e.g., for OS-level media notifications and Android Auto).
  Future<Result<void, Failure>> updateQueue(
    List<Song> songs, {
    required int currentIndex,
  });

  /// Reactive streams for the Presentation layer to drive the Now Playing UI.
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;
  
  /// Emits an event whenever the current track finishes playing naturally,
  /// allowing the orchestration layer to trigger auto-advance.
  Stream<void> get completedStream;
}