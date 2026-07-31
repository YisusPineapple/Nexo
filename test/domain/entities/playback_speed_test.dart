import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/domain/entities/playback_speed.dart';

void main() {
  group('PlaybackSpeed.create', () {
    test('accepts the default 1.0x normal speed', () {
      final result = PlaybackSpeed.create(multiplier: 1.0);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.pitchCorrectionEnabled, isTrue);
      expect(result.valueOrNull?.multiplier, 1.0);
    });

    test('rejects a multiplier below 0.5x', () {
      expect(PlaybackSpeed.create(multiplier: 0.25).isErr, isTrue);
    });

    test('rejects a multiplier above 2.0x', () {
      expect(PlaybackSpeed.create(multiplier: 2.5).isErr, isTrue);
    });

    test('boundary values 0.5x and 2.0x are both valid', () {
      expect(PlaybackSpeed.create(multiplier: 0.5).isOk, isTrue);
      expect(PlaybackSpeed.create(multiplier: 2.0).isOk, isTrue);
    });

    test(
        'two instances built from the same nominal speed are equal '
        'even if the doubles differ by floating-point noise', () {
      final a = PlaybackSpeed.create(multiplier: 1.25).valueOrNull!;
      // Simulates a value arrived at through arithmetic rather than a
      // clean literal (e.g. a UI step computed as 0.05 * 25).
      final noisyMultiplier = 0.05 * 25; // not bit-identical to 1.25
      final b = PlaybackSpeed.create(multiplier: noisyMultiplier).valueOrNull!;

      expect(a, equals(b));
    });
  });

  group('PlaybackSpeed.copyWith', () {
    test('changes multiplier while preserving pitchCorrectionEnabled', () {
      final base = PlaybackSpeed.create(
        multiplier: 1.0,
        pitchCorrectionEnabled: false,
      ).valueOrNull!;

      final updated = base.copyWith(multiplier: 1.5).valueOrNull!;

      expect(updated.multiplier, 1.5);
      expect(updated.pitchCorrectionEnabled, isFalse);
    });

    test('re-validates the merged result', () {
      final base = PlaybackSpeed.create(multiplier: 1.0).valueOrNull!;
      final updated = base.copyWith(multiplier: 3.0);
      expect(updated.isErr, isTrue);
    });
  });
}
