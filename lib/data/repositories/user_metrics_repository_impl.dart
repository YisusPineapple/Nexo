import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/item_interaction.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/user_metrics_repository.dart';
import '../../domain/value_objects/song_id.dart';
import '../local/app_database.dart';
import '../local/mappers/song_mapper.dart';

class UserMetricsRepositoryImpl implements UserMetricsRepository {
  UserMetricsRepositoryImpl(this._db);

  final AppDatabase _db;
  final SongMapper _songMapper = const SongMapper();

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
      return Ok(row.interaction == 1
          ? InteractionType.like
          : InteractionType.dislike);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to get interaction', cause: e));
    }
  }

  // --- For You implementations ---

  @override
  Future<Result<List<Song>, Failure>> getRecentlyPlayed(
      {int limit = 50}) async {
    try {
      final songIds = await _getSongIdsFromCustomQuery(
        '''
        SELECT song_id, MAX(timestamp_utc_ms) as last_played
        FROM playback_history
        WHERE song_id IN (SELECT id FROM songs WHERE is_missing = 0)
        GROUP BY song_id
        ORDER BY last_played DESC
        LIMIT ?;
        ''',
        [limit],
      );
      return await _fetchSongsByIds(songIds);
    } catch (e) {
      return Err(
          UnexpectedFailure('Failed to fetch recently played', cause: e));
    }
  }

  @override
  Future<Result<List<Song>, Failure>> getTopTracks({int limit = 20}) async {
    try {
      final songIds = await _getSongIdsFromCustomQuery(
        '''
        SELECT song_id, COUNT(*) as play_count
        FROM playback_history
        WHERE song_id IN (SELECT id FROM songs WHERE is_missing = 0)
        GROUP BY song_id
        ORDER BY play_count DESC
        LIMIT ?;
        ''',
        [limit],
      );
      return await _fetchSongsByIds(songIds);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch top tracks', cause: e));
    }
  }

  @override
  Future<Result<List<Song>, Failure>> getDailyMix({
    int likedLimit = 20,
    int topLimit = 30,
    int maxTotal = 50,
  }) async {
    try {
      // 1. Fetch Liked Songs (CORRECTED: use item_id, not song_id)
      final likedQuery = _db.customSelect(
        '''
        SELECT item_id
        FROM item_interactions
        WHERE item_type = 'song' AND interaction = 1
        LIMIT ?;
        ''',
        variables: [Variable(likedLimit)],
      );
      final likedRows = await likedQuery.get();
      final likedIds =
          likedRows.map((r) => r.data['item_id'] as String).toSet();

      // 2. Fetch Top Tracks
      final topIdsResult = await _getSongIdsFromCustomQuery(
        '''
        SELECT song_id
        FROM playback_history
        WHERE song_id IN (SELECT id FROM songs WHERE is_missing = 0)
        GROUP BY song_id
        ORDER BY COUNT(*) DESC
        LIMIT ?;
        ''',
        [topLimit],
      );
      final topIds = topIdsResult.toSet();

      // 3. Combine and shuffle
      var combined = {...likedIds, ...topIds}.toList();
      combined.shuffle(Random());

      // 4. Trim to maxTotal
      if (combined.length > maxTotal) {
        combined = combined.sublist(0, maxTotal);
      }

      // 5. If the list is empty, fallback to random songs
      if (combined.isEmpty) {
        final randomRows = await _db.customSelect(
          '''
          SELECT id
          FROM songs
          WHERE is_missing = 0
          ORDER BY RANDOM()
          LIMIT ?;
          ''',
          variables: [Variable(maxTotal)],
        ).get();
        combined = randomRows.map((r) => r.data['id'] as String).toList();
      }

      return await _fetchSongsByIds(combined);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to generate daily mix', cause: e));
    }
  }

  // --- Helpers ---

  /// Executes a custom SELECT that returns a single 'song_id' column and
  /// extracts the list of IDs.
  Future<List<String>> _getSongIdsFromCustomQuery(
    String sql,
    List<Object?> args,
  ) async {
    final results = await _db
        .customSelect(
          sql,
          variables: args.map((a) => Variable(a)).toList(),
        )
        .get();
    return results.map((r) => r.data['song_id'] as String).toList();
  }

  /// Fetches full [SongRow]s by a list of IDs and maps them to Domain [Song]s.
  /// Skips any row that fails to map (e.g., corrupted data) instead of failing
  /// the entire list.
  Future<Result<List<Song>, Failure>> _fetchSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return const Ok([]);

    final rows =
        await (_db.select(_db.songs)..where((t) => t.id.isIn(ids))).get();

    final songs = <Song>[];
    for (final row in rows) {
      final result = _songMapper.toEntity(row);
      if (result.isOk) {
        songs.add(result.valueOrNull!);
      } else {
        // Log the error but continue processing other songs
        // (in a real app you might use a logger)
        // ignore: avoid_print
        print('Skipping invalid song row: $result');
      }
    }
    return Ok(songs);
  }
}
