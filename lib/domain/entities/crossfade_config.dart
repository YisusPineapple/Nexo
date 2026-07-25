import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

enum CrossfadeMode {
  /// No crossfade; tracks play back-to-back (gapless silence trimming
  /// from SilenceTrimPoints still applies).
  disabled,

  /// Constant overlap duration for every transition, set by
  /// [CrossfadeConfig.duration]. The "basic" behavior found in most
  /// existing music players.
  fixed,

  /// The engine analyzes the outgoing/incoming track's energy (and
  /// beat grid when available) to choose an overlap duration and
  /// volume curve that avoids fading over a vocal entrance or a
  /// dramatic pause, instead of blindly cutting the last N seconds.
  intelligent,

  /// "AutoMix" / DJ-style: same analysis as [intelligent], but the
  /// engine is free to choose the duration itself (ignoring
  /// [CrossfadeConfig.duration]) so consecutive songs feel like one
  /// continuous mix.
  autoMix,
}

/// Immutable, self-validating configuration for track-to-track
/// transitions.
///
/// Uses [Duration] — a dart:core type, not an external package —
/// instead of a raw int-seconds field, so a fixed crossfade can be
/// tuned to sub-second precision (e.g. 2.5s) from a fine slider, and
/// so the value reaches just_audio's Duration-based APIs without a
/// lossy seconds-to-ms conversion at the data-layer boundary.
final class CrossfadeConfig {
  const CrossfadeConfig._({
    required this.mode,
    required this.duration,
  });

  final CrossfadeMode mode;

  /// Overlap length. Authoritative only for [CrossfadeMode.fixed]; for
  /// [CrossfadeMode.intelligent] and [CrossfadeMode.autoMix] this is
  /// kept as the user's last manual value so the UI has something to
  /// show if they switch back to `fixed`, but the engine computes its
  /// own duration in those modes.
  final Duration duration;

  static const Duration minDuration = Duration.zero;
  static const Duration maxDuration = Duration(seconds: 12);

  static const CrossfadeConfig disabled = CrossfadeConfig._(
    mode: CrossfadeMode.disabled,
    duration: Duration.zero,
  );

  static Result<CrossfadeConfig, Failure> create({
    required CrossfadeMode mode,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (duration < minDuration || duration > maxDuration) {
      return Err(ValidationFailure(
        'Crossfade duration must be between ${minDuration.inMilliseconds}ms '
        'and ${maxDuration.inMilliseconds}ms, got '
        '${duration.inMilliseconds}ms.',
      ));
    }
    return Ok(CrossfadeConfig._(mode: mode, duration: duration));
  }

  Result<CrossfadeConfig, Failure> copyWith({
    CrossfadeMode? mode,
    Duration? duration,
  }) {
    return CrossfadeConfig.create(
      mode: mode ?? this.mode,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrossfadeConfig &&
          other.mode == mode &&
          other.duration == duration);

  @override
  int get hashCode => Object.hash(mode, duration);
}