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
    );
  }

  SongsCompanion toCompanion(Song song) {
    return SongsCompanion.insert(
      id: song.id.value,
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
    );
  }
}