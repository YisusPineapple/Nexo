import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as amr;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Metadata extracted from a single audio file, normalized into the shape
/// `_buildSong` in `song_repository_impl.dart` consumes.
///
/// Produced by [MetadataDatasource.read], which — since T9 — uses
/// `audio_metadata_reader` (pure Dart) as its sole backend. The previous
/// implementation used `flutter_taglib` (C++ FFI), whose release AAR
/// shipped a 32-bit ARM binary under `lib/arm64-v8a/`; every arm64
/// Android device rejected it at `System.loadLibrary` and silently
/// degraded scanned songs to "Unknown Artist" with no cover.
/// See ARCHITECTURE.md §2.6.
class ExtractedMetadata {
  const ExtractedMetadata({
    required this.title,
    required this.artist,
    required this.albumArtist,
    required this.album,
    required this.trackNumber,
    required this.discNumber,
    required this.duration,
    required this.genres,
    required this.year,
    required this.coverArtBytes,
    required this.replayGainTrackDb,
    required this.replayGainAlbumDb,
  });

  final String? title;
  final String? artist;

  /// Always `null` since T9. `audio_metadata_reader`'s public
  /// `AudioMetadata` surface does not expose `ALBUMARTIST` under any name
  /// (verified against 1.8.0 in the T9 spike). The field is kept on this
  /// class so `_buildSong`'s signature and its call site do not change;
  /// note that `_buildSong` never read this field even before T9 — it was
  /// dead code in the TagLib path too. A future ticket that surfaces
  /// album artist from the tag should populate it here rather than
  /// reintroduce a second metadata reader.
  final String? albumArtist;

  final String? album;
  final int? trackNumber;
  final int? discNumber;
  final Duration duration;
  final List<String> genres;
  final int? year;
  final Uint8List? coverArtBytes;
  final double? replayGainTrackDb;
  final double? replayGainAlbumDb;

  factory ExtractedMetadata.empty() {
    return const ExtractedMetadata(
      title: null,
      artist: null,
      albumArtist: null,
      album: null,
      trackNumber: null,
      discNumber: null,
      duration: Duration.zero,
      genres: [],
      year: null,
      coverArtBytes: null,
      replayGainTrackDb: null,
      replayGainAlbumDb: null,
    );
  }
}

/// Single source of truth for audio-file metadata on every platform.
///
/// Uses `audio_metadata_reader` (pure Dart, no native code) as its only
/// backend. This is deliberate and load-bearing: the previous primary
/// reader (`flutter_taglib`, C++ FFI via a git fork with no version tag)
/// shipped a 32-bit `libflutter_taglib_native.so` under `arm64-v8a/` in
/// its release AAR, which `System.loadLibrary` rejects on every arm64
/// Android device. See ARCHITECTURE.md §2.6 for the full diagnosis and
/// the T9 ticket.
///
/// Methods return `Future` even though `amr`'s public API is synchronous,
/// for two reasons: (1) to preserve the surface `_buildSong` already
/// `await`s, and (2) so a future backend swap (e.g. Rust + `lofty`,
/// ticket T9.1) can move to a genuinely async implementation without
/// touching call sites.
class MetadataDatasource {
  const MetadataDatasource();

  Future<ExtractedMetadata> read(File file, {bool extractCover = true}) async {
    try {
      // Primary pass. `getImage: extractCover` is passed straight through:
      // when extractCover is false (the scanner path during indexing), amr
      // skips reading APIC/Vorbis METADATA_BLOCK_PICTURE bytes entirely —
      // that is what keeps the initial scan cheap.
      final meta = amr.readMetadata(file, getImage: extractCover);

      // ReplayGain is only recoverable via `readAllMetadata()`'s typed
      // subclasses. `VorbisMetadata` (FLAC, Opus, Ogg Vorbis) exposes
      // `replayGainTrackGain` / `replayGainAlbumGain` as `List<String>`;
      // `Mp3Metadata`, `Mp4Metadata` and `RiffMetadata` (MP3, M4A, WAV,
      // AIFF) do not. MP3/M4A ReplayGain is therefore a known regression
      // vs. the pre-T9 TagLib path on desktop — where TagLib DID load and
      // read it — tracked as a separate P1. On Android the MP3 ReplayGain
      // never worked (TagLib never loaded there), so this is not a
      // regression on the target device.
      //
      // `getImage: false` is passed explicitly. The package's default is
      // `getImage: true`, which would force a decode of every embedded
      // picture in this second pass even when the caller asked for
      // `extractCover: false` — silently negating the whole point of the
      // cheaper scanner path. Vorbis comment ReplayGain lives in a text
      // metadata block, never in a picture block, so this flag has zero
      // effect on the values we are actually reading here.
      double? replayGainTrackDb;
      double? replayGainAlbumDb;
      try {
        final allTag = amr.readAllMetadata(file, getImage: false);
        if (allTag is amr.VorbisMetadata) {
          if (allTag.replayGainTrackGain.isNotEmpty) {
            replayGainTrackDb = _parseDbValue(allTag.replayGainTrackGain.first);
          }
          if (allTag.replayGainAlbumGain.isNotEmpty) {
            replayGainAlbumDb = _parseDbValue(allTag.replayGainAlbumGain.first);
          }
        }
      } catch (_) {
        // Best-effort. A malformed or absent ReplayGain tag must never
        // fail the whole read — the rest of the metadata is still valid.
      }

      // Cover: prefer the explicitly-typed front cover; fall back to
      // `pictures.first` only when no picture declares itself as
      // `PictureType.coverFront`. APIC / picture frames with type 3 are
      // the conventional "album art" slot; picking the first picture
      // blindly can grab a back cover or an artist photo instead.
      Uint8List? coverBytes;
      if (extractCover && meta.pictures.isNotEmpty) {
        amr.Picture? front;
        for (final picture in meta.pictures) {
          if (picture.pictureType == amr.PictureType.coverFront) {
            front = picture;
            break;
          }
        }
        coverBytes = (front ?? meta.pictures.first).bytes;
      }

      return ExtractedMetadata(
        title: _nonEmpty(meta.title),
        artist: _nonEmpty(meta.artist),
        albumArtist: null,
        album: _nonEmpty(meta.album),
        trackNumber: meta.trackNumber,
        discNumber: meta.discNumber,
        duration: meta.duration ?? Duration.zero,
        genres: meta.genres.where((g) => g.trim().isNotEmpty).toList(),
        year: meta.year?.year,
        coverArtBytes: coverBytes,
        replayGainTrackDb: replayGainTrackDb,
        replayGainAlbumDb: replayGainAlbumDb,
      );
    } catch (e) {
      debugPrint('audio_metadata_reader read failed for ${file.path}: $e');
      return ExtractedMetadata.empty();
    }
  }

  Future<String?> cacheCoverArt({
    required Uint8List coverBytes,
    required String cacheDirectory,
    required String coverId,
  }) async {
    final outPath = p.join(cacheDirectory, '$coverId.jpg');
    final file = File(outPath);

    if (await file.exists()) {
      return outPath;
    }

    await Directory(cacheDirectory).create(recursive: true);

    try {
      await file.writeAsBytes(coverBytes);
      return outPath;
    } catch (e) {
      debugPrint('Failed to write cover art for $coverId: $e');
      return null;
    }
  }

  /// Trims [raw] and returns `null` for empty or whitespace-only strings,
  /// so a tag that exists but carries only whitespace is treated the same
  /// as a missing tag by `_buildSong`'s `??` fallback chain. Matches the
  /// behavior of the pre-T9 TagLib path's `_first` helper.
  String? _nonEmpty(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Strips the trailing `" dB"` suffix that Vorbis comment ReplayGain
  /// tags conventionally carry (e.g. `"-6.50 dB"`) and parses the
  /// remainder as a `double`. Returns `null` on any parse failure rather
  /// than throwing — a malformed ReplayGain tag is not a reason to fail
  /// the whole read, same posture as the surrounding best-effort block.
  double? _parseDbValue(String raw) {
    final cleaned = raw.replaceAll(' dB', '').trim();
    return double.tryParse(cleaned);
  }
}
