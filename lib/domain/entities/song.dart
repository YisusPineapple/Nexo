import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../value_objects/album_id.dart';
import '../value_objects/artist_id.dart';
import '../value_objects/song_id.dart';
import 'audio_format.dart';
import 'silence_trim_points.dart';

final class Song {
  const Song._({
    required this.id,
    required this.title,
    required this.trackArtistId,
    required this.albumArtistId,
    required this.albumId,
    required this.trackNumber,
    required this.discNumber,
    required this.duration,
    required this.filePath,
    required this.format,
    required this.fileSizeBytes,
    required this.genreNames,
    required this.year,
    required this.coverArtPath,
    required this.silenceTrim,
    required this.replayGainTrackDb,
    required this.replayGainAlbumDb,
    required this.dateAddedUtc,
    required this.isMissing,
    required this.lyricOffsetMs,
  });

  final SongId id;
  final String title;
  final ArtistId trackArtistId;
  final ArtistId? albumArtistId;
  final AlbumId? albumId;
  final int? trackNumber;
  final int? discNumber;
  final Duration duration;
  final String filePath;
  final AudioFormat format;
  final int fileSizeBytes;
  final List<String> genreNames;
  final int? year;
  final String? coverArtPath;
  final SilenceTrimPoints silenceTrim;
  final double? replayGainTrackDb;
  final double? replayGainAlbumDb;
  final DateTime dateAddedUtc;
  final bool isMissing;
  final int lyricOffsetMs;

  static Result<Song, Failure> create({
    required SongId id,
    required String title,
    required ArtistId trackArtistId,
    ArtistId? albumArtistId,
    AlbumId? albumId,
    int? trackNumber,
    int? discNumber,
    required Duration duration,
    required String filePath,
    required AudioFormat format,
    required int fileSizeBytes,
    List<String> genreNames = const [],
    int? year,
    String? coverArtPath,
    SilenceTrimPoints silenceTrim = SilenceTrimPoints.none,
    double? replayGainTrackDb,
    double? replayGainAlbumDb,
    required DateTime dateAddedUtc,
    bool isMissing = false,
    int lyricOffsetMs = 0,
  }) {
    if (duration.isNegative) {
      return Err(ValidationFailure(
        'Song duration cannot be negative, got $duration for "$title".',
      ));
    }
    if (fileSizeBytes < 0) {
      return Err(ValidationFailure(
        'Song fileSizeBytes cannot be negative, got $fileSizeBytes for '
        '"$title".',
      ));
    }
    if (filePath.isEmpty) {
      return const Err(ValidationFailure('Song filePath cannot be empty.'));
    }
    return Ok(Song._(
      id: id,
      title: title,
      trackArtistId: trackArtistId,
      albumArtistId: albumArtistId,
      albumId: albumId,
      trackNumber: trackNumber,
      discNumber: discNumber,
      duration: duration,
      filePath: filePath,
      format: format,
      fileSizeBytes: fileSizeBytes,
      genreNames: genreNames,
      year: year,
      coverArtPath: coverArtPath,
      silenceTrim: silenceTrim,
      replayGainTrackDb: replayGainTrackDb,
      replayGainAlbumDb: replayGainAlbumDb,
      dateAddedUtc: dateAddedUtc,
      isMissing: isMissing,
      lyricOffsetMs: lyricOffsetMs,
    ));
  }

  Song copyWith({
    String? coverArtPath,
    double? replayGainTrackDb,
    double? replayGainAlbumDb,
    bool? isMissing,
    int? lyricOffsetMs,
  }) {
    return Song._(
      id: id,
      title: title,
      trackArtistId: trackArtistId,
      albumArtistId: albumArtistId,
      albumId: albumId,
      trackNumber: trackNumber,
      discNumber: discNumber,
      duration: duration,
      filePath: filePath,
      format: format,
      fileSizeBytes: fileSizeBytes,
      genreNames: genreNames,
      year: year,
      coverArtPath: coverArtPath ?? this.coverArtPath,
      silenceTrim: silenceTrim,
      replayGainTrackDb: replayGainTrackDb ?? this.replayGainTrackDb,
      replayGainAlbumDb: replayGainAlbumDb ?? this.replayGainAlbumDb,
      dateAddedUtc: dateAddedUtc,
      isMissing: isMissing ?? this.isMissing,
      lyricOffsetMs: lyricOffsetMs ?? this.lyricOffsetMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Song && other.id == id);

  @override
  int get hashCode => id.hashCode;
}