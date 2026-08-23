import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/playback_settings.dart';
import '../../domain/entities/playback_speed.dart';
import '../../domain/usecases/update_playback_settings_usecase.dart';
import 'library_providers.dart';
import 'repository_providers.dart';

final playbackSettingsProvider = FutureProvider<PlaybackSettings>((ref) async {
  final repo = ref.watch(playbackRepositoryProvider);
  final result = await repo.getPlaybackSettings();
  return result.when(ok: (settings) => settings, err: (e) => throw e);
});

final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref);
});

class SettingsController {
  SettingsController(this._ref);
  final Ref _ref;

  Future<void> updateCrossfade(
    CrossfadeMode mode,
    Duration duration, {
    required bool isAutoDuration,
  }) async {
    final currentAsync = _ref.read(playbackSettingsProvider);
    if (currentAsync is! AsyncData) return;

    final current = currentAsync.value!;
    final newCrossfadeResult = CrossfadeConfig.create(
      mode: mode,
      duration: duration,
      isAutoDuration: isAutoDuration,
    );

    if (newCrossfadeResult.isOk) {
      final newSettings = current.copyWith(crossfade: newCrossfadeResult.valueOrNull);
      await _applyAndSave(newSettings);
    } else {
      final errorMsg = newCrossfadeResult.when(
        ok: (_) => null,
        err: (e) => e.message,
      );
      debugPrint('Error updating crossfade: $errorMsg');
    }
  }

  Future<void> updateSpeed(double multiplier, bool pitchCorrection) async {
    final currentAsync = _ref.read(playbackSettingsProvider);
    if (currentAsync is! AsyncData) return;

    final current = currentAsync.value!;
    final newSpeedResult = PlaybackSpeed.create(
      multiplier: multiplier,
      pitchCorrectionEnabled: pitchCorrection,
    );

    if (newSpeedResult.isOk) {
      final newSettings = current.copyWith(speed: newSpeedResult.valueOrNull);
      await _applyAndSave(newSettings);
    } else {
      final errorMsg = newSpeedResult.when(
        ok: (_) => null,
        err: (e) => e.message,
      );
      debugPrint('Error updating speed: $errorMsg');
    }
  }

  Future<void> _applyAndSave(PlaybackSettings settings) async {
    final useCase = UpdatePlaybackSettingsUseCase(
      _ref.read(playbackRepositoryProvider),
      _ref.read(audioPlayerRepositoryProvider),
    );
    final result = await useCase.call(settings);
    if (result.isOk) {
      _ref.invalidate(playbackSettingsProvider);
    } else {
      final errorMsg = result.when(
        ok: (_) => null,
        err: (e) => e.message,
      );
      debugPrint('Error applying and saving settings: $errorMsg');
    }
  }

  Future<String?> forceLibraryRefresh() async {
    try {
      // FIX: Added 'await' to satisfy the unawaited_futures lint rule
      await _ref.read(indexDirectoriesControllerProvider.notifier).refreshLibrary();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// --- Equalizer State (UI Only for now) ---
final equalizerBandsProvider = StateProvider<List<double>>((ref) {
  return List.filled(10, 0.0);
});
final equalizerEnabledProvider = StateProvider<bool>((ref) => false);
final equalizerPresetProvider = StateProvider<String>((ref) => 'Custom');