import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

/// Immutable, self-validating playback speed setting.
///
/// Stored internally as integer hundredths (e.g. 125 == 1.25x) rather
/// than a raw [double] multiplier. A tolerance-based `==` was
/// considered and rejected: comparing doubles with an epsilon breaks
/// transitivity (a≈b and b≈c does not guarantee a≈c), which is
/// unacceptable for a value object's equality contract. Storing an
/// int instead keeps equality exact and free of IEEE 754 drift if a
/// caller ever derives a new speed arithmetically (e.g. `speed * 1.1`).
/// The one unavoidable double conversion happens at the [multiplier]
/// getter, which is where the data layer reads a value to hand to the
/// native player.
final class PlaybackSpeed {
  const PlaybackSpeed._({
    required this.speedHundredths,
    required this.pitchCorrectionEnabled,
  });

  /// e.g. 100 == 1.0x, 125 == 1.25x, 200 == 2.0x.
  final int speedHundredths;

  final bool pitchCorrectionEnabled;

  /// Convenience accessor for callers (UI, native player bindings)
  /// that need a double. This is a derived value, never the source of
  /// truth or the basis for equality.
  double get multiplier => speedHundredths / 100;

  static const int minSpeedHundredths = 50; // 0.5x
  static const int maxSpeedHundredths = 200; // 2.0x

  static const PlaybackSpeed normal = PlaybackSpeed._(
    speedHundredths: 100,
    pitchCorrectionEnabled: true,
  );

  /// Accepts a [double] multiplier at the boundary (where UI sliders
  /// naturally produce doubles) and rounds it to the nearest hundredth
  /// before validating, so e.g. a slider value of 1.2500001 and a
  /// manually typed 1.25 both resolve to the exact same stored value.
  static Result<PlaybackSpeed, Failure> create({
    required double multiplier,
    bool pitchCorrectionEnabled = true,
  }) {
    final hundredths = (multiplier * 100).round();

    if (hundredths < minSpeedHundredths || hundredths > maxSpeedHundredths) {
      return Err(ValidationFailure(
        'Playback speed must be between ${minSpeedHundredths / 100}x and '
        '${maxSpeedHundredths / 100}x, got ${multiplier}x.',
      ));
    }
    return Ok(PlaybackSpeed._(
      speedHundredths: hundredths,
      pitchCorrectionEnabled: pitchCorrectionEnabled,
    ));
  }

  Result<PlaybackSpeed, Failure> copyWith({
    double? multiplier,
    bool? pitchCorrectionEnabled,
  }) {
    return PlaybackSpeed.create(
      multiplier: multiplier ?? this.multiplier,
      pitchCorrectionEnabled:
          pitchCorrectionEnabled ?? this.pitchCorrectionEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackSpeed &&
          other.speedHundredths == speedHundredths &&
          other.pitchCorrectionEnabled == pitchCorrectionEnabled);

  @override
  int get hashCode => Object.hash(speedHundredths, pitchCorrectionEnabled);
}
