import 'crossfade_config.dart';
import 'playback_speed.dart';

/// Engine-wide playback configuration — as opposed to PlaybackQueue,
/// which holds PER-QUEUE state (song order, current index, repeat
/// mode).
///
/// This is the entity PlaybackQueue's own docstring pointed to when it
/// deliberately excluded crossfade and speed: both apply uniformly
/// across whichever queue is currently playing, not to one queue in
/// isolation, so they don't belong on PlaybackQueue itself.
///
/// Composing two ALREADY-VALIDATED value objects ([CrossfadeConfig],
/// [PlaybackSpeed]), so unlike Song or PlaybackQueue there's no
/// additional cross-field invariant to check at this level — `create`
/// can't fail, so this stays a plain immutable class instead of
/// returning a Result.
final class PlaybackSettings {
  const PlaybackSettings({
    required this.crossfade,
    required this.speed,
  });

  final CrossfadeConfig crossfade;
  final PlaybackSpeed speed;

  /// What a fresh install / first launch starts with.
  static const PlaybackSettings defaults = PlaybackSettings(
    crossfade: CrossfadeConfig.disabled,
    speed: PlaybackSpeed.normal,
  );

  PlaybackSettings copyWith({
    CrossfadeConfig? crossfade,
    PlaybackSpeed? speed,
  }) {
    return PlaybackSettings(
      crossfade: crossfade ?? this.crossfade,
      speed: speed ?? this.speed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackSettings &&
          other.crossfade == crossfade &&
          other.speed == speed);

  @override
  int get hashCode => Object.hash(crossfade, speed);
}