import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

enum CrossfadeMode {
  disabled,
  fixed,
  intelligent,
  autoMix,
}

final class CrossfadeConfig {
  const CrossfadeConfig._({
    required this.mode,
    required this.duration,
    required this.isAutoDuration,
  });

  final CrossfadeMode mode;
  final Duration duration;
  final bool isAutoDuration;

  static const Duration minDuration = Duration.zero;
  static const Duration maxDuration = Duration(seconds: 12);

  static const CrossfadeConfig disabled = CrossfadeConfig._(
    mode: CrossfadeMode.disabled,
    duration: Duration.zero,
    isAutoDuration: false,
  );

  static Result<CrossfadeConfig, Failure> create({
    required CrossfadeMode mode,
    Duration duration = const Duration(seconds: 4),
    bool isAutoDuration = false,
  }) {
    if (mode == CrossfadeMode.disabled) {
      return Ok(CrossfadeConfig._(
        mode: mode,
        duration: Duration.zero,
        isAutoDuration: false,
      ));
    }

    // Duration validation only if manual
    if (!isAutoDuration) {
      if (duration < minDuration || duration > maxDuration) {
        return Err(ValidationFailure(
          'Crossfade duration must be between ${minDuration.inMilliseconds}ms '
          'and ${maxDuration.inMilliseconds}ms, got ${duration.inMilliseconds}ms.',
        ));
      }
    }

    // Auto duration only available in Intelligent or AutoMix
    if (isAutoDuration &&
        (mode == CrossfadeMode.fixed || mode == CrossfadeMode.disabled)) {
      return const Err(ValidationFailure(
        'Auto duration is only available for Intelligent and AutoMix modes.',
      ));
    }

    return Ok(CrossfadeConfig._(
      mode: mode,
      duration: isAutoDuration
          ? duration
          : duration, // We save the value in case it changes to "manual"
      isAutoDuration: isAutoDuration,
    ));
  }

  Result<CrossfadeConfig, Failure> copyWith({
    CrossfadeMode? mode,
    Duration? duration,
    bool? isAutoDuration,
  }) {
    return CrossfadeConfig.create(
      mode: mode ?? this.mode,
      duration: duration ?? this.duration,
      isAutoDuration: isAutoDuration ?? this.isAutoDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrossfadeConfig &&
          other.mode == mode &&
          other.duration == duration &&
          other.isAutoDuration == isAutoDuration);

  @override
  int get hashCode => Object.hash(mode, duration, isAutoDuration);
}
