import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/domain/entities/crossfade_config.dart';

void main() {
  group('CrossfadeConfig.create', () {
    test('accepts a duration within the valid range', () {
      final result = CrossfadeConfig.create(
        mode: CrossfadeMode.fixed,
        duration: const Duration(milliseconds: 6500),
      );

      expect(result.isOk, isTrue);
      expect(
        result.valueOrNull?.duration,
        const Duration(milliseconds: 6500),
      );
      expect(result.valueOrNull?.mode, CrossfadeMode.fixed);
    });

    test('accepts sub-second precision', () {
      final result = CrossfadeConfig.create(
        mode: CrossfadeMode.fixed,
        duration: const Duration(milliseconds: 2500),
      );
      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.duration.inMilliseconds, 2500);
    });

    test('rejects a negative duration', () {
      final result = CrossfadeConfig.create(
        mode: CrossfadeMode.fixed,
        duration: const Duration(milliseconds: -1),
      );
      expect(result.isErr, isTrue);
    });

    test('rejects a duration above the 12s ceiling', () {
      final result = CrossfadeConfig.create(
        mode: CrossfadeMode.intelligent,
        duration: const Duration(seconds: 13),
      );
      expect(result.isErr, isTrue);
    });

    test('boundary values 0s and 12s are both valid', () {
      expect(
        CrossfadeConfig.create(
          mode: CrossfadeMode.fixed,
          duration: Duration.zero,
        ).isOk,
        isTrue,
      );
      expect(
        CrossfadeConfig.create(
          mode: CrossfadeMode.fixed,
          duration: const Duration(seconds: 12),
        ).isOk,
        isTrue,
      );
    });
  });

  group('CrossfadeConfig.copyWith', () {
    test('re-validates the merged result', () {
      final base = CrossfadeConfig.create(
        mode: CrossfadeMode.fixed,
        duration: const Duration(seconds: 5),
      ).valueOrNull!;

      final updated = base.copyWith(duration: const Duration(seconds: 20));

      expect(updated.isErr, isTrue);
    });
  });
}
