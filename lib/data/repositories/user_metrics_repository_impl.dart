import 'package:drift/drift.dart';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/item_interaction.dart';
import '../../domain/repositories/user_metrics_repository.dart';
import '../../domain/value_objects/song_id.dart';
import '../local/app_database.dart';

class UserMetricsRepositoryImpl implements UserMetricsRepository {
  UserMetricsRepositoryImpl(this._db);
  
  final AppDatabase _db;

  @override
  Future<Result<void, Failure>> logSongPlay(SongId songId) async {
    try {
      await _db.into(_db.playbackHistory).insert(
            PlaybackHistoryCompanion.insert(
              songId: songId.value,
              timestampUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
            ),
          );
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to log song play', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setInteraction({
    required String itemId,
    required ItemType itemType,
    required InteractionType? interaction,
  }) async {
    try {
      if (interaction == null) {
        await (_db.delete(_db.itemInteractions)
              ..where((t) =>
                  t.itemId.equals(itemId) & t.itemType.equals(itemType.name)))
            .go();
      } else {
        final value = interaction == InteractionType.like ? 1 : -1;
        await _db.into(_db.itemInteractions).insertOnConflictUpdate(
              ItemInteractionsCompanion.insert(
                itemId: itemId,
                itemType: itemType.name,
                interaction: value,
                timestampUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            );
      }
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to set interaction', cause: e));
    }
  }

  @override
  Future<Result<InteractionType?, Failure>> getInteraction({
    required String itemId,
    required ItemType itemType,
  }) async {
    try {
      final row = await (_db.select(_db.itemInteractions)
            ..where((t) =>
                t.itemId.equals(itemId) & t.itemType.equals(itemType.name)))
          .getSingleOrNull();
      
      if (row == null) return const Ok(null);
      return Ok(row.interaction == 1 ? InteractionType.like : InteractionType.dislike);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to get interaction', cause: e));
    }
  }
}