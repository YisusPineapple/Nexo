import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as amr;
import 'package:path/path.dart' as p;

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

/// High-performance metadata extractor using C++ FFI (TagLib) and a hybrid fallback.
/// Replaces the pure-Dart image extraction to drop scan times from minutes to seconds.
class TagLibMetadataDatasource {
  const TagLibMetadataDatasource();

  String? _first(Map<String, List<String>> props, String key) {
    final list = props[key];
    if (list == null || list.isEmpty) return null;
    final val = list.first.trim();
    return val.isEmpty ? null : val;
  }

  Future<ExtractedMetadata> read(File file, {bool extractCover = true}) async {
    TagLibFile? tagFile;
    try {
      tagFile = TagLibFile.open(file.path);
      if (tagFile == null) return ExtractedMetadata.empty();

      final props = tagFile.properties;
      final artwork = extractCover ? tagFile.coverData : null;

      // TagLib handles ReplayGain natively
      final trackGainStr = _first(props, 'REPLAYGAIN_TRACK_GAIN') ??
          _first(props, 'RG_TRACK_GAIN');
      final albumGainStr = _first(props, 'REPLAYGAIN_ALBUM_GAIN') ??
          _first(props, 'RG_ALBUM_GAIN');

      final trackNumStr = _first(props, 'TRACKNUMBER');
      final discNumStr = _first(props, 'DISCNUMBER');
      final yearStr = _first(props, 'DATE') ?? _first(props, 'YEAR');

      // FIX: Hybrid duration extraction
      // flutter_taglib doesn't expose audio properties, so we check the LENGTH tag first.
      // If missing, we fallback to audio_metadata_reader (which is very fast if getImage is false).
      Duration duration = Duration.zero;
      final lengthStr = _first(props, 'LENGTH');
      if (lengthStr != null) {
        duration = Duration(milliseconds: int.tryParse(lengthStr) ?? 0);
      } else {
        try {
          final amrMeta = amr.readMetadata(file, getImage: false);
          duration = amrMeta.duration ?? Duration.zero;
        } catch (_) {}
      }

      return ExtractedMetadata(
        title: _first(props, 'TITLE'),
        artist: _first(props, 'ARTIST'),
        albumArtist: _first(props, 'ALBUMARTIST'),
        album: _first(props, 'ALBUM'),
        trackNumber: trackNumStr != null
            ? int.tryParse(trackNumStr.split('/').first)
            : null,
        discNumber: discNumStr != null
            ? int.tryParse(discNumStr.split('/').first)
            : null,
        duration: duration,
        genres: props['GENRE']
                ?.map((g) => g.trim())
                .where((g) => g.isNotEmpty)
                .toList() ??
            [],
        year: yearStr != null ? int.tryParse(yearStr.split('-').first) : null,
        coverArtBytes: artwork,
        replayGainTrackDb: trackGainStr != null
            ? double.tryParse(trackGainStr.replaceAll(' dB', ''))
            : null,
        replayGainAlbumDb: albumGainStr != null
            ? double.tryParse(albumGainStr.replaceAll(' dB', ''))
            : null,
      );
    } catch (e) {
      debugPrint('TagLib read failed for ${file.path}: $e');
      return ExtractedMetadata.empty();
    } finally {
      tagFile?.close();
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
}
