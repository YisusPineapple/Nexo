import 'dart:convert';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as reader;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
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
}

class SongMetadataReader {
  const SongMetadataReader();

  String? _sanitize(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }
    // Encode to UTF-8 (which replaces unpaired surrogates with U+FFFD) and decode back safely
    final cleaned =
        utf8.decode(utf8.encode(input), allowMalformed: true).trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  List<String> _sanitizeGenres(List<String>? genres) {
    if (genres == null || genres.isEmpty) {
      return const [];
    }
    final result = <String>[];
    for (final g in genres) {
      final cleaned = _sanitize(g);
      if (cleaned != null) {
        result.add(cleaned);
      }
    }
    return result;
  }

  Future<ExtractedMetadata> read(File file, {bool extractCover = true}) async {
    final metadata = reader.readMetadata(file, getImage: extractCover);

    Uint8List? coverBytes;
    if (extractCover && metadata.pictures.isNotEmpty) {
      coverBytes = metadata.pictures.first.bytes;
    }

    double? trackGain;
    double? albumGain;
    try {
      final raf = await file.open();
      final bytes = await raf.read(131072); // 128 KB
      await raf.close();

      final headerStr = String.fromCharCodes(bytes);

      final trackMatch =
          RegExp(r'REPLAYGAIN_TRACK_GAIN.*?([-+0-9.]+)', caseSensitive: false)
              .firstMatch(headerStr);
      if (trackMatch != null) {
        trackGain = double.tryParse(trackMatch.group(1)!);
      }

      final albumMatch =
          RegExp(r'REPLAYGAIN_ALBUM_GAIN.*?([-+0-9.]+)', caseSensitive: false)
              .firstMatch(headerStr);
      if (albumMatch != null) {
        albumGain = double.tryParse(albumMatch.group(1)!);
      }
    } catch (e) {
      debugPrint('ReplayGain parse error for ${file.path}: $e');
    }

    return ExtractedMetadata(
      title: _sanitize(metadata.title),
      artist: _sanitize(metadata.artist),
      albumArtist: null,
      album: _sanitize(metadata.album),
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      duration: metadata.duration ?? Duration.zero,
      genres: _sanitizeGenres(metadata.genres),
      year: metadata.year?.year,
      coverArtBytes: coverBytes,
      replayGainTrackDb: trackGain,
      replayGainAlbumDb: albumGain,
    );
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
      final decoded = img.decodeImage(coverBytes);
      if (decoded != null) {
        img.Image processed = decoded;
        if (decoded.width > 500 || decoded.height > 500) {
          processed = img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 500 : null,
            height: decoded.height > decoded.width ? 500 : null,
            interpolation: img.Interpolation.average,
          );
        }
        final compressed = img.encodeJpg(processed, quality: 75);
        await file.writeAsBytes(compressed);
        return outPath;
      }
    } catch (e) {
      debugPrint('Cover art resize error for $coverId: $e');
    }

    await file.writeAsBytes(coverBytes);
    return outPath;
  }
}
