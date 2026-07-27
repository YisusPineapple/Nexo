import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../value_objects/album_id.dart';
import '../value_objects/artist_id.dart';
import '../value_objects/song_id.dart';
import 'audio_format.dart';
import 'silence_trim_points.dart';

/// A single indexed audio file and its metadata.
///
/// Song is an Entity, not a Value Object: two Song instances are "the
/// same song" if they share an [id], even after fields like
/// [isMissing] or [coverArtPath] change following a re-scan.
/// Equality and hashCode are identity-based (by [id]) rather than
/// structural — comparing all ~15 fields would be both semantically
/// wrong (a re-tagged file is still the same Song) and needlessly
/// expensive to recompute on every scroll-triggered rebuild across a
/// 15,000-item list.
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
  });

  final SongId id;
  final String title;

  /// The performing artist for THIS track. Distinguished from
  /// [albumArtistId] per the mandatory "Álbum artist vs Track artist"
  /// library distinction (e.g. a guest track on a various-artists
  /// compilation).
  final ArtistId trackArtistId;

  /// Null when the source file has no album-artist tag (common on
  /// singles or files ripped without that field).
  final ArtistId? albumArtistId;

  /// Null for a track that isn't part of an indexed album.
  final AlbumId? albumId;

  final int? trackNumber;
  final int? discNumber;
  final Duration duration;

  /// Kept as a plain String rather than a value object — unlike the
  /// ID types, there's no risk of mixing this path up with another
  /// kind of path on this entity, so the extra type doesn't earn its
  /// cost yet.
  final String filePath;

  final AudioFormat format;
  final int fileSizeBytes;

  /// A file can carry more than one genre tag (ID3v2.4 and Vorbis
  /// Comments both allow repeated genre fields), so this is a list,
  /// not a single String. Empty, never null, when untagged.
  final List<String> genreNames;

  final int? year;

  /// Path to the pre-resized 512x512 cached cover, never the original
  /// file (which may be 3000x3000+ and must not be loaded into
  /// memory just to render a list thumbnail). Null until the indexing
  /// isolate has produced the cache entry.
  final String? coverArtPath;

  final SilenceTrimPoints silenceTrim;

  /// ReplayGain values in dB for loudness normalization. Null when
  /// the file carries no ReplayGain tag; the audio engine falls back
  /// to no normalization rather than guessing a value.
  final double? replayGainTrackDb;
  final double? replayGainAlbumDb;

  final DateTime dateAddedUtc;

  /// True when the file behind [filePath] wasn't found on the last
  /// scan. The library shows such songs grayed out per the resilience
  /// requirements, instead of silently dropping them from playlists
  /// that reference them.
  final bool isMissing;

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
    ));
  }

  /// Scoped to only the fields that plausibly change without a full
  /// re-index (art cache populated later, ReplayGain computed later,
  /// missing-flag toggled on re-scan). Unlike the Value Objects in
  /// this codebase, this never fails — each field is independently
  /// valid with no cross-field invariant to re-check. If a future
  /// field needs re-validation, switch this to return Result.
  Song copyWith({
    String? coverArtPath,
    double? replayGainTrackDb,
    double? replayGainAlbumDb,
    bool? isMissing,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Song && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
