import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nexo/data/sources/metadata_datasource.dart';

/// Path to the synthetic T9 fixtures. Kept as a directory constant so
/// every test names its file the same way the generator script does.
const _fixtureDir = 'test/fixtures/t9_amr';

File _fixture(String name) => File('$_fixtureDir/$name');

void main() {
  const datasource = MetadataDatasource();

  // If any fixture is missing (fresh checkout before running
  // tool/generate_t9_fixtures.sh), skip the whole file rather than fail
  // on FileNotFoundException — a missing fixture is an environment
  // problem, not a code regression.
  setUpAll(() {
    final required = [
      '01_flac_replaygain.flac',
      '02_mp3_no_rg.mp3',
      '03_mp3_with_rg_tags.mp3',
      '04_sample.m4a',
      '05_sample.opus',
      '06_sample.wav',
      '07_corrupt.mp3',
      '08_sample.ogg',
      '09_sample.aiff',
      '10_with_cover.flac',
    ];
    final missing = required.where((n) => !_fixture(n).existsSync()).toList();
    if (missing.isNotEmpty) {
      markTestSkipped(
          'T9 fixtures missing: $missing. Run tool/generate_t9_fixtures.sh.');
    }
  });

  // ---------------------------------------------------------------------
  // Tag read-back — the baseline every format must satisfy. If these
  // fail, T9's whole premise (audio_metadata_reader as sole backend) is
  // broken before we even get to the ReplayGain assertions below.
  // ---------------------------------------------------------------------
  group('tag read-back (all formats)', () {
    test('FLAC', () async {
      final meta = await datasource.read(_fixture('01_flac_replaygain.flac'));
      expect(meta.title, 'T9 Fixture');
      expect(meta.artist, 'T9 Fixture Artist');
      expect(meta.album, 'T9 Fixture Album');
      expect(meta.trackNumber, 1);
      expect(meta.year, 2026);
      expect(meta.genres, contains('Test'));
    });

    test('MP3', () async {
      final meta = await datasource.read(_fixture('02_mp3_no_rg.mp3'));
      expect(meta.title, 'T9 Fixture');
      expect(meta.artist, 'T9 Fixture Artist');
      expect(meta.album, 'T9 Fixture Album');
      expect(meta.trackNumber, 1);
      expect(meta.year, 2026);
    });

    test('M4A', () async {
      final meta = await datasource.read(_fixture('04_sample.m4a'));
      expect(meta.title, 'T9 Fixture');
      expect(meta.artist, 'T9 Fixture Artist');
    });

    test('Opus', () async {
      final meta = await datasource.read(_fixture('05_sample.opus'));
      expect(meta.title, 'T9 Fixture');
      expect(meta.artist, 'T9 Fixture Artist');
    });

    test('WAV', () async {
      final meta = await datasource.read(_fixture('06_sample.wav'));
      expect(meta.title, 'T9 Fixture');
    });

    test('OGG Vorbis', () async {
      final meta = await datasource.read(_fixture('08_sample.ogg'));
      expect(meta.title, 'T9 Fixture');
      expect(meta.artist, 'T9 Fixture Artist');
    });

    test('AIFF', () async {
      final meta = await datasource.read(_fixture('09_sample.aiff'));
      expect(meta.title, 'T9 Fixture');
    });
  });

  // ---------------------------------------------------------------------
  // ReplayGain — the load-bearing T9 assertion.
  //
  // Vorbis comment carriers (FLAC, Opus) DO expose ReplayGain through
  // audio_metadata_reader's VorbisMetadata. Everything else does NOT,
  // regardless of whether the tags are present in the file. That last
  // point is what 03 proves: it has ID3v2 TXXX ReplayGain frames and
  // still comes back null. That is the P1 — MP3/M4A ReplayGain on
  // desktop regressed vs. the pre-T9 TagLib path, and the fixture
  // codifies it as intentional current behavior so any future reader
  // swap has to explicitly flip these assertions.
  // ---------------------------------------------------------------------
  group('ReplayGain (T9: Vorbis-only)', () {
    test('FLAC exposes track + album ReplayGain as double', () async {
      final meta = await datasource.read(_fixture('01_flac_replaygain.flac'));
      expect(meta.replayGainTrackDb, closeTo(-3.50, 0.001));
      expect(meta.replayGainAlbumDb, closeTo(-2.10, 0.001));
    });

    test('Opus exposes track + album ReplayGain as double', () async {
      final meta = await datasource.read(_fixture('05_sample.opus'));
      expect(meta.replayGainTrackDb, closeTo(-3.50, 0.001));
      expect(meta.replayGainAlbumDb, closeTo(-2.10, 0.001));
    });

    test('MP3 without tags returns null ReplayGain', () async {
      final meta = await datasource.read(_fixture('02_mp3_no_rg.mp3'));
      expect(meta.replayGainTrackDb, isNull);
      expect(meta.replayGainAlbumDb, isNull);
    });

    test(
        'MP3 WITH ID3v2 ReplayGain tags STILL returns null (P1: '
        'Mp3Metadata does not expose them)', () async {
      final meta = await datasource.read(_fixture('03_mp3_with_rg_tags.mp3'));
      expect(meta.replayGainTrackDb, isNull,
          reason: 'This is the P1 contract: the tags exist in the file '
              '(id3v2 TXXX frames) but audio_metadata_reader does not '
              'surface them for MP3. If this ever starts returning a '
              'value, MP3 ReplayGain has been fixed and the ticket that '
              'tracks it as a regression can close — but flip this '
              'assertion deliberately, do not let it change silently.');
      expect(meta.replayGainAlbumDb, isNull);
    });

    test('M4A returns null ReplayGain (no Mp4Metadata support)', () async {
      final meta = await datasource.read(_fixture('04_sample.m4a'));
      expect(meta.replayGainTrackDb, isNull);
    });

    test('WAV returns null ReplayGain (no RiffMetadata support)', () async {
      final meta = await datasource.read(_fixture('06_sample.wav'));
      expect(meta.replayGainTrackDb, isNull);
    });

    test('AIFF returns null ReplayGain (no RiffMetadata support)', () async {
      final meta = await datasource.read(_fixture('09_sample.aiff'));
      expect(meta.replayGainTrackDb, isNull);
    });

    test('OGG without RG tags returns null (Vorbis path, empty list)',
        () async {
      final meta = await datasource.read(_fixture('08_sample.ogg'));
      expect(meta.replayGainTrackDb, isNull);
    });
  });

  // ---------------------------------------------------------------------
  // Cover art extraction.
  // ---------------------------------------------------------------------
  group('cover art', () {
    test('extractCover: true returns the embedded JPEG bytes', () async {
      final meta = await datasource.read(_fixture('10_with_cover.flac'));
      expect(meta.coverArtBytes, isNotNull);
      // JPEG magic — SOI (0xFFD8) followed by APP0 (0xFFE0). The
      // generator embeds a 16x16 MJPEG, so any other header means the
      // picture block was misparsed or the wrong stream was extracted.
      final bytes = meta.coverArtBytes!;
      expect(bytes.length, greaterThan(4));
      expect(bytes[0], 0xFF);
      expect(bytes[1], 0xD8);
    });

    test('extractCover: false returns null even when a cover is embedded',
        () async {
      final meta = await datasource.read(
        _fixture('10_with_cover.flac'),
        extractCover: false,
      );
      expect(meta.coverArtBytes, isNull,
          reason: 'The scanner path calls read(extractCover: false) '
              'specifically to skip picture decoding. If this ever '
              'returns non-null, the cheap-scan optimization is broken.');
    });

    test('file without cover returns null', () async {
      final meta = await datasource.read(_fixture('01_flac_replaygain.flac'));
      expect(meta.coverArtBytes, isNull);
    });
  });

  // ---------------------------------------------------------------------
  // Error handling — the reader must NEVER throw. T9's contract is that
  // any parse failure collapses to ExtractedMetadata.empty(), which
  // _buildSong then turns into a fallback row (the exact rows the
  // recovery pass in commit 3 rewrites later).
  // ---------------------------------------------------------------------
  group('error handling', () {
    test('corrupt MP3 does not throw; returns empty metadata (title null)',
        () async {
      final meta = await datasource.read(_fixture('07_corrupt.mp3'));
      expect(meta.title, isNull,
          reason: 'A truncated MP3 must come back as empty metadata, '
              'not as a partially-populated ExtractedMetadata. This is '
              'what lets _buildSong assign the fallback artist and lets '
              'the T9 recovery pass find the row later.');
      expect(meta.artist, isNull);
      expect(meta.coverArtBytes, isNull);
    });
  });
}
