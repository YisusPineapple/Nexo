import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/item_interaction.dart';
import '../repositories/user_metrics_repository.dart';
import '../value_objects/song_id.dart';
import 'use_case.dart';

final class LogSongPlayUseCase implements UseCase<void, SongId> {
  LogSongPlayUseCase(this._repository);
  final UserMetricsRepository _repository;

  @override
  Future<Result<void, Failure>> call(SongId songId) {
    return _repository.logSongPlay(songId);
  }
}

typedef ToggleInteractionParams = ({
  String itemId,
  ItemType itemType,
  InteractionType interaction,
});

final class ToggleInteractionUseCase implements UseCase<void, ToggleInteractionParams> {
  ToggleInteractionUseCase(this._repository);
  final UserMetricsRepository _repository;

  @override
  Future<Result<void, Failure>> call(ToggleInteractionParams params) async {
    final currentResult = await _repository.getInteraction(
      itemId: params.itemId,
      itemType: params.itemType,
    );
    
    return currentResult.asyncAndThen((current) {
      // If the user clicks the same interaction again, remove it (toggle off).
      // Otherwise, set the new interaction.
      final next = current == params.interaction ? null : params.interaction;
      return _repository.setInteraction(
        itemId: params.itemId,
        itemType: params.itemType,
        interaction: next,
      );
    });
  }
}