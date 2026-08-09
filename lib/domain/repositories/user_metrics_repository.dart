import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/item_interaction.dart';
import '../value_objects/song_id.dart';

abstract interface class UserMetricsRepository {
  Future<Result<void, Failure>> logSongPlay(SongId songId);
  
  Future<Result<void, Failure>> setInteraction({
    required String itemId,
    required ItemType itemType,
    required InteractionType? interaction, // null removes the interaction
  });
  
  Future<Result<InteractionType?, Failure>> getInteraction({
    required String itemId,
    required ItemType itemType,
  });
}