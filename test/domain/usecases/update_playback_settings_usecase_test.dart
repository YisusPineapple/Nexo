import 'package:test/test.dart';
import 'package:nexo/core/error/failures.dart';
import 'package:nexo/domain/entities/crossfade_config.dart';
import 'package:nexo/domain/entities/playback_settings.dart';
import 'package:nexo/domain/entities/playback_speed.dart';
import 'package:nexo/domain/usecases/update_playback_settings_usecase.dart';

import '../repositories/fakes/fake_audio_player_repository.dart';
import '../repositories/fakes/fake_playback_repository.dart';

void main() {
  group('UpdatePlaybackSettingsUseCase', () {
    test('persists the new settings and applies them to the live engine',
        () async {
      final playbackRepo = FakePlaybackRepository();
      final audioRepo = FakeAudioPlayerRepository();
      final useCase = UpdatePlaybackSettingsUseCase(playbackRepo, audioRepo);

      final newSettings = PlaybackSettings(
        crossfade: CrossfadeConfig.create(
          mode: CrossfadeMode.fixed,
          duration: const Duration(seconds: 6),
        ).valueOrNull!,
        speed: PlaybackSpeed.create(multiplier: 1.25).valueOrNull!,
      );

      final result = await useCase.call(newSettings);

      expect(result.isOk, isTrue);
      expect(audioRepo.appliedSpeed?.multiplier, 1.25);
      expect(audioRepo.appliedCrossfade?.duration, const Duration(seconds: 6));

      final persisted = await playbackRepo.getPlaybackSettings();
      expect(persisted.valueOrNull, newSettings);
    });

    test(
        'propagates a failure from the engine without silently '
        'succeeding', () async {
      final audioRepo = FakeAudioPlayerRepository()
        ..failWith = const UnexpectedFailure('engine unavailable');
      final useCase =
          UpdatePlaybackSettingsUseCase(FakePlaybackRepository(), audioRepo);

      final result = await useCase.call(PlaybackSettings.defaults);

      expect(result.isErr, isTrue);
    });
  });
}