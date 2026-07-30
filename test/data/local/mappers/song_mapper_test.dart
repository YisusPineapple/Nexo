import 'package:test/test.dart';

import 'package:nexo/data/local/app_database.dart';
import 'package:nexo/data/local/mappers/song_mapper.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/silence_trim_points.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

Song _fullSong() {
  return Song.create(
    id: const SongId('s1'),
    title: 'Test Song',
    trackArtistId: const ArtistId('artist-1'),
    albumArtistId: const ArtistId('album-artist-1'),
    albumId: const AlbumId('album-1'),
    trackNumber: 3,
    discNumber: 1,
    duration: const Duration(minutes: 4, seconds: 12),
    filePath: '/music/test.flac',
    format: AudioFormat.flac,
    fileSizeBytes: 25000000,
    genreNames: const ['Ambient', 'Electronic'],
    year: 2020,
    coverArtPath: '/cache/covers/s1.jpg',
    silenceTrim: const SilenceTrimPoints(
      leadingSilenceMs: 120,
      trailingSilenceMs: 340,
    ),
    replayGainTrackDb: -6.5,
    replayGainAlbumDb: -7.1,
    dateAddedUtc: DateTime.utc(2026, 1, 15, 10, 30),
    isMissing: true,
  ).valueOrNull!;
}

/// Builds the [SongRow] a real DB round-trip through [companion]
/// would produce, without needing an actual [AppDatabase] for this
/// pure-mapping test.
SongRow _rowFrom(SongsCompanion companion) {
  return SongRow(
    id: companion.id.value,
    title: companion.title.value,
    trackArtistId: companion.trackArtistId.value,
    albumArtistId: companion.albumArtistId.value,
    albumId: companion.albumId.value,
    trackNumber: companion.trackNumber.value,
    discNumber: companion.discNumber.value,
    durationMs: companion.durationMs.value,
    filePath: companion.filePath.value,
    format: companion.format.value,
    fileSizeBytes: companion.fileSizeBytes.value,
    genreNames: companion.genreNames.value,
    year: companion.year.value,
    coverArtPath: companion.coverArtPath.value,
    leadingSilenceMs: companion.leadingSilenceMs.value,
    trailingSilenceMs: companion.trailingSilenceMs.value,
    replayGainTrackDb: companion.replayGainTrackDb.value,
    replayGainAlbumDb: companion.replayGainAlbumDb.value,
    dateAddedUtcMs: companion.dateAddedUtcMs.value,
    isMissing: companion.isMissing.value,
  );
}

void main() {
  const mapper = SongMapper();

  test('toCompanion -> toEntity round-trips every field exactly', () {
    final original = _fullSong();
    final roundTripped =
        mapper.toEntity(_rowFrom(mapper.toCompanion(original))).valueOrNull!;

    expect(roundTripped.id, original.id);
    expect(roundTripped.title, original.title);
    expect(roundTripped.trackArtistId, original.trackArtistId);
    expect(roundTripped.albumArtistId, original.albumArtistId);
    expect(roundTripped.albumId, original.albumId);
    expect(roundTripped.trackNumber, original.trackNumber);
    expect(roundTripped.discNumber, original.discNumber);
    expect(roundTripped.duration, original.duration);
    expect(roundTripped.format, original.format);
    expect(roundTripped.genreNames, original.genreNames);
    expect(roundTripped.year, original.year);
    expect(roundTripped.coverArtPath, original.coverArtPath);
    expect(roundTripped.silenceTrim, original.silenceTrim);
    expect(roundTripped.replayGainTrackDb, original.replayGainTrackDb);
    expect(roundTripped.dateAddedUtc, original.dateAddedUtc);
    expect(roundTripped.isMissing, original.isMissing);
  });

  test('handles a song with no optional fields set', () {
    final minimal = Song.create(
      id: const SongId('s2'),
      title: 'Minimal',
      trackArtistId: const ArtistId('artist-2'),
      duration: const Duration(minutes: 2),
      filePath: '/music/minimal.mp3',
      format: AudioFormat.mp3,
      fileSizeBytes: 1000,
      dateAddedUtc: DateTime.utc(2026, 1, 1),
    ).valueOrNull!;

    final companion = mapper.toCompanion(minimal);
    expect(companion.albumArtistId.value, isNull);
    expect(companion.albumId.value, isNull);

    final roundTripped = mapper.toEntity(_rowFrom(companion)).valueOrNull!;
    expect(roundTripped.albumArtistId, isNull);
    expect(roundTripped.genreNames, isEmpty);
  });
}
