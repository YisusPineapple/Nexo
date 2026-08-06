import 'package:drift/drift.dart';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/crossfade_config.dart';
import '../../domain/entities/playback_queue.dart';
import '../../domain/entities/playback_settings.dart';
import '../../domain/entities/playback_speed.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/playback_repository.dart';
import '../../domain/value_objects/queue_id.dart';
import '../local/app_database.dart';
import '../local/mappers/playback_queue_mapper.dart';
import '../local/mappers/song_mapper.dart';

/// Real [PlaybackRepository] backed by [AppDatabase]. Song identities
/// referenced by a queue are resolved through the same [Songs] table
/// SongRepositoryImpl writes to — both repositories share one
/// [AppDatabase] instance, wired up at the app's composition root.
class PlaybackRepositoryImpl implements PlaybackRepository {
  PlaybackRepositoryImpl(
    this._db, {
    PlaybackQueueMapper queueMapper = const PlaybackQueueMapper(),
    SongMapper songMapper = const SongMapper(),
  })  : _queueMapper = queueMapper,
        _songMapper = songMapper;

  final AppDatabase _db;
  final PlaybackQueueMapper _queueMapper;
  final SongMapper _songMapper;

  @override
  Future<Result<PlaybackQueue, Failure>> getQueue(QueueId id) async {
    final row = await (_db.select(_db.playbackQueues)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    if (row == null) {
      return Err(NotFoundFailure('No queue found with id "${id.value}".'));
    }
    return _hydrateQueue(row);
  }

  @override
  Future<Result<List<PlaybackQueue>, Failure>> getAllQueues() async {
    final rows = await _db.select(_db.playbackQueues).get();
    final queues = <PlaybackQueue>[];
    for (final row in rows) {
      final result = await _hydrateQueue(row);
      switch (result) {
        case Err(error: final e):
          return Err(e);
        case Ok(value: final queue):
          queues.add(queue);
      }
    }
    return Ok(queues);
  }

  Future<Result<PlaybackQueue, Failure>> _hydrateQueue(
    PlaybackQueueRow row,
  ) async {
    final queueSongRows = await (_db.select(_db.queueSongs)
          ..where((t) => t.queueId.equals(row.id)))
        .get();

    final currentRefs = queueSongRows
        .where((r) => r.listKind == 'current')
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final preShuffleRefs = queueSongRows
        .where((r) => r.listKind == 'preShuffle')
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final referencedIds = {
      ...currentRefs.map((r) => r.songId),
      ...preShuffleRefs.map((r) => r.songId),
    }.toList();

    final songRows = referencedIds.isEmpty
        ? <SongRow>[]
        : await (_db.select(_db.songs)..where((t) => t.id.isIn(referencedIds)))
            .get();
    final songById = {for (final songRow in songRows) songRow.id: songRow};

    Result<List<Song>, Failure> resolve(List<QueueSongRow> refs) {
      final songs = <Song>[];
      for (final ref in refs) {
        final songRow = songById[ref.songId];
        if (songRow == null) {
          return Err(NotFoundFailure(
            'Queue "${row.id}" references song "${ref.songId}", which no '
            'longer exists in the library.',
          ));
        }
        final entityResult = _songMapper.toEntity(songRow);
        switch (entityResult) {
          case Err(error: final e):
            return Err(e);
          case Ok(value: final song):
            songs.add(song);
        }
      }
      return Ok(songs);
    }

    final currentResult = resolve(currentRefs);
    final List<Song> currentSongs;
    switch (currentResult) {
      case Err(error: final e):
        return Err(e);
      case Ok(value: final songs):
        currentSongs = songs;
    }

    List<Song>? preShuffleSongs;
    if (row.shuffleEnabled) {
      final preShuffleResult = resolve(preShuffleRefs);
      switch (preShuffleResult) {
        case Err(error: final e):
          return Err(e);
        case Ok(value: final songs):
          preShuffleSongs = songs;
      }
    }

    return _queueMapper.toEntity(
      row: row,
      currentSongs: currentSongs,
      preShuffleSongs: preShuffleSongs,
    );
  }

  @override
  Future<Result<void, Failure>> saveQueue(PlaybackQueue queue) async {
    await _db.transaction(() async {
      await _db
          .into(_db.playbackQueues)
          .insertOnConflictUpdate(_queueMapper.toQueueCompanion(queue));
      await (_db.delete(_db.queueSongs)
            ..where((t) => t.queueId.equals(queue.id.value)))
          .go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.queueSongs,
          _queueMapper.toQueueSongCompanions(queue),
        );
      });
    });
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> deleteQueue(QueueId id) async {
    final deletedCount = await (_db.delete(_db.playbackQueues)
          ..where((t) => t.id.equals(id.value)))
        .go();
    if (deletedCount == 0) {
      return Err(NotFoundFailure('No queue found with id "${id.value}".'));
    }
    await (_db.delete(_db.queueSongs)..where((t) => t.queueId.equals(id.value)))
        .go();
    return const Ok(null);
  }

  @override
  Future<Result<PlaybackSettings, Failure>> getPlaybackSettings() async {
    // FIX: Use .get() and take the last row to avoid 'Too many elements' crash
    // if the database already has duplicated rows from the previous bug.
    final rows = await _db.select(_db.playbackSettingsTable).get();
    if (rows.isEmpty) return const Ok(PlaybackSettings.defaults);

    final row = rows.last;

    final crossfadeResult = CrossfadeConfig.create(
      mode: row.crossfadeMode,
      duration: Duration(milliseconds: row.crossfadeDurationMs),
    );
    final speedResult = PlaybackSpeed.create(
      multiplier: row.speedHundredths / 100,
      pitchCorrectionEnabled: row.pitchCorrectionEnabled,
    );

    final CrossfadeConfig crossfade;
    switch (crossfadeResult) {
      case Err(error: final e):
        return Err(e);
      case Ok(value: final v):
        crossfade = v;
    }

    final PlaybackSpeed speed;
    switch (speedResult) {
      case Err(error: final e):
        return Err(e);
      case Ok(value: final v):
        speed = v;
    }

    return Ok(PlaybackSettings(crossfade: crossfade, speed: speed));
  }

  @override
  Future<Result<void, Failure>> savePlaybackSettings(
    PlaybackSettings settings,
  ) async {
    await _db.transaction(() async {
      // Clean up any duplicate rows
      await _db.delete(_db.playbackSettingsTable).go();

      // Explicitly set id to 0 so SQLite doesn't auto-increment
      await _db.into(_db.playbackSettingsTable).insert(
            PlaybackSettingsTableCompanion.insert(
              id: const Value(0),
              crossfadeMode: settings.crossfade.mode,
              crossfadeDurationMs: settings.crossfade.duration.inMilliseconds,
              speedHundredths: settings.speed.speedHundredths,
              pitchCorrectionEnabled: settings.speed.pitchCorrectionEnabled,
            ),
          );
    });
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> saveActiveSession(
    ActiveSessionSnapshot snapshot,
  ) async {
    await _db.transaction(() async {
      // Clean up any duplicate rows
      await _db.delete(_db.activeSessionTable).go();

      // Explicitly set id to 0
      await _db.into(_db.activeSessionTable).insert(
            ActiveSessionTableCompanion.insert(
              id: const Value(0),
              activeQueueId: snapshot.activeQueueId.value,
              positionMs: snapshot.position.inMilliseconds,
            ),
          );
    });
    return const Ok(null);
  }

  @override
  Future<Result<ActiveSessionSnapshot?, Failure>> getLastSession() async {
    // FIX: Same protection as settings
    final rows = await _db.select(_db.activeSessionTable).get();
    if (rows.isEmpty) return const Ok(null);

    final row = rows.last;
    return Ok((
      activeQueueId: QueueId(row.activeQueueId),
      position: Duration(milliseconds: row.positionMs),
    ));
  }
}
