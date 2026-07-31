import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/domain/entities/crossfade_config.dart';
import 'package:nexo/domain/entities/playback_settings.dart';
import 'package:nexo/domain/entities/playback_speed.dart';

void main() {
  group('PlaybackSettings', () {
    test('defaults pairs disabled crossfade with normal speed', () {
      expect(PlaybackSettings.defaults.crossfade, CrossfadeConfig.disabled);
      expect(PlaybackSettings.defaults.speed, PlaybackSpeed.normal);
    });

    test('copyWith updates only the given field', () {
      final fasterSpeed = PlaybackSpeed.create(multiplier: 1.5).valueOrNull!;
      final updated = PlaybackSettings.defaults.copyWith(speed: fasterSpeed);

      expect(updated.speed, fasterSpeed);
      expect(updated.crossfade, PlaybackSettings.defaults.crossfade);
    });

    test('two instances with equal crossfade and speed are equal', () {
      const a = PlaybackSettings.defaults;
      const b = PlaybackSettings(
        crossfade: CrossfadeConfig.disabled,
        speed: PlaybackSpeed.normal,
      );
      expect(a, equals(b));
    });
  });
}
