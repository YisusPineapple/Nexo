import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/playback_settings.dart';
import '../repositories/audio_player_repository.dart';
import '../repositories/playback_repository.dart';
import 'use_case.dart';

/// Persists new engine-wide [PlaybackSettings] AND applies them to the
/// live engine immediately — bundled deliberately, since from the
/// user's perspective dragging the crossfade or speed slider is ONE
/// action ("change this now"), not two. Splitting "persist" and
/// "apply live" across separate calls at the Presentation layer would
/// leak that this is a single business operation up out of Domain.
final class UpdatePlaybackSettingsUseCase
    implements UseCase<void, PlaybackSettings> {
  UpdatePlaybackSettingsUseCase(
    this._playbackRepository,
    this._audioPlayerRepository,
  );

  final PlaybackRepository _playbackRepository;
  final AudioPlayerRepository _audioPlayerRepository;

  @override
  Future<Result<void, Failure>> call(PlaybackSettings params) async {
    final saveResult = await _playbackRepository.savePlaybackSettings(params);
    return saveResult.asyncAndThen((_) async {
      final speedResult = await _audioPlayerRepository.setSpeed(params.speed);
      return speedResult.asyncAndThen(
        (_) => _audioPlayerRepository.setCrossfade(params.crossfade),
      );
    });
  }
}
