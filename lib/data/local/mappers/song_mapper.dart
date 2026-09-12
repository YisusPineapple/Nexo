import 'package:drift/drift.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/silence_trim_points.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/value_objects/album_id.dart';
import '../../../domain/value_objects/artist_id.dart';
import '../../../domain/value_objects/song_id.dart';
import '../app_database.dart';

class SongMapper {
  const SongMapper();

  Result<Song, Failure> toEntity(SongRow row) {
    return Song.create(
      id: SongId(row.id),
      title: row.title,
      trackArtistId: ArtistId(row.trackArtistId),
      albumArtistId:
          row.albumArtistId == null ? null : ArtistId(row.albumArtistId!),
      albumId: row.albumId == null ? null : AlbumId(row.albumId!),
      trackNumber: row.trackNumber,
      discNumber: row.discNumber,
      duration: Duration(milliseconds: row.durationMs),
      filePath: row.filePath,
      format: row.format,
      fileSizeBytes: row.fileSizeBytes,
      genreNames: row.genreNames,
      year: row.year,
      coverArtPath: row.coverArtPath,
      silenceTrim: SilenceTrimPoints(
        leadingSilenceMs: row.leadingSilenceMs,
        trailingSilenceMs: row.trailingSilenceMs,
      ),
      replayGainTrackDb: row.replayGainTrackDb,
      replayGainAlbumDb: row.replayGainAlbumDb,
      dateAddedUtc: DateTime.fromMillisecondsSinceEpoch(
        row.dateAddedUtcMs,
        isUtc: true,
      ),
      isMissing: row.isMissing,
      lyricOffsetMs: row.lyricOffsetMs,
      hasNoCover: row.hasNoCover,
      sectionKey: row.sectionKey,
    );
  }

  /// Full companion, including `id`. Used by callers that genuinely own
  /// the id (tests seeding specific rows, restore-from-backup flows).
  /// Do NOT use this from the scanner: the scanner cannot know the
  /// SQLite-assigned id ahead of time, and providing one would clobber
  /// the existing stable id on conflict. See [toCompanionForUpsert].
  ///
  /// `id` is wrapped in `Value<int>` because Drift makes a single-column
  /// IntColumn PK optional in the generated insert companion (it is
  /// treated as a rowid alias), so the parameter type is `Value<int>`,
  /// not `int`.
  SongsCompanion toCompanion(Song song) {
    return SongsCompanion.insert(
      id: Value(song.id.value),
      title: song.title,
      trackArtistId: song.trackArtistId.value,
      albumArtistId: Value(song.albumArtistId?.value),
      albumId: Value(song.albumId?.value),
      trackNumber: Value(song.trackNumber),
      discNumber: Value(song.discNumber),
      durationMs: song.duration.inMilliseconds,
      filePath: song.filePath,
      format: song.format,
      fileSizeBytes: song.fileSizeBytes,
      genreNames: song.genreNames,
      year: Value(song.year),
      coverArtPath: Value(song.coverArtPath),
      leadingSilenceMs: Value(song.silenceTrim.leadingSilenceMs),
      trailingSilenceMs: Value(song.silenceTrim.trailingSilenceMs),
      replayGainTrackDb: Value(song.replayGainTrackDb),
      replayGainAlbumDb: Value(song.replayGainAlbumDb),
      dateAddedUtcMs: song.dateAddedUtc.toUtc().millisecondsSinceEpoch,
      isMissing: Value(song.isMissing),
      lyricOffsetMs: Value(song.lyricOffsetMs),
      hasNoCover: Value(song.hasNoCover),
      sectionKey: Value(song.sectionKey),
    );
  }

  /// Companion variant that OMITS `id`, for the scanner's upsert path.
  ///
  /// The scanner resolves conflicts on `songs.file_path` (which carries a
  /// UNIQUE constraint — see `songs_table.dart`). On conflict, the existing
  /// row is updated in place and its stable integer id is preserved (the
  /// absent id field is simply not written). On first insert, SQLite
  /// assigns a new id via the rowid alias.
  ///
  /// Providing an id here would be wrong in both directions: on conflict
  /// it would overwrite the existing stable id with a placeholder, and on
  /// first insert it would consume a specific integer that may collide.
  SongsCompanion toCompanionForUpsert(Song song) {
    return SongsCompanion(
      title: Value(song.title),
      trackArtistId: Value(song.trackArtistId.value),
      albumArtistId: Value(song.albumArtistId?.value),
      albumId: Value(song.albumId?.value),
      trackNumber: Value(song.trackNumber),
      discNumber: Value(song.discNumber),
      durationMs: Value(song.duration.inMilliseconds),
      filePath: Value(song.filePath),
      format: Value(song.format),
      fileSizeBytes: Value(song.fileSizeBytes),
      genreNames: Value(song.genreNames),
      year: Value(song.year),
      coverArtPath: Value(song.coverArtPath),
      leadingSilenceMs: Value(song.silenceTrim.leadingSilenceMs),
      trailingSilenceMs: Value(song.silenceTrim.trailingSilenceMs),
      replayGainTrackDb: Value(song.replayGainTrackDb),
      replayGainAlbumDb: Value(song.replayGainAlbumDb),
      dateAddedUtcMs: Value(song.dateAddedUtc.toUtc().millisecondsSinceEpoch),
      isMissing: Value(song.isMissing),
      lyricOffsetMs: Value(song.lyricOffsetMs),
      hasNoCover: Value(song.hasNoCover),
      sectionKey: Value(song.sectionKey),
    );
  }
}
