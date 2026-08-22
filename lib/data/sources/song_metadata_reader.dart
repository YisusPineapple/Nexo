import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as reader;
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
  });

  final String? title;
  final String? artist;
  final String? albumArtist; // FIX: Added albumArtist to help with deduplication
  final String? album;
  final int? trackNumber;
  final int? discNumber;
  final Duration duration;
  final List<String> genres;
  final int? year;
  final Uint8List? coverArtBytes;
}

class SongMetadataReader {
  const SongMetadataReader();

  Future<ExtractedMetadata> read(File file) async {
    final metadata = reader.readMetadata(file, getImage: true);

    Uint8List? coverBytes;
    if (metadata.pictures.isNotEmpty) {
      coverBytes = metadata.pictures.first.bytes;
    }

    return ExtractedMetadata(
      title: metadata.title,
      artist: metadata.artist,
      albumArtist: null, // audio_metadata_reader doesn't expose TPE2 yet
      album: metadata.album,
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      duration: metadata.duration ?? Duration.zero,
      genres: metadata.genres,
      year: metadata.year?.year,
      coverArtBytes: coverBytes,
    );
  }

  Future<String?> cacheCoverArt({
    required Uint8List coverBytes,
    required String cacheDirectory,
    required String coverId, // FIX: Renamed from songId to coverId
  }) async {
    final outPath = p.join(cacheDirectory, '$coverId.jpg');
    final file = File(outPath);
    
    // FIX: Deduplication. If the cover already exists for this album, skip writing.
    if (await file.exists()) {
      return outPath;
    }

    await Directory(cacheDirectory).create(recursive: true);
    await file.writeAsBytes(coverBytes);
    return outPath;
  }
}