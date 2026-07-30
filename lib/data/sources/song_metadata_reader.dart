import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as reader;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// The subset of a file's tags SongRepositoryImpl actually needs. No
/// Domain knowledge here on purpose — audio_metadata_reader and image
/// stay behind this one seam, never imported by the repository
/// directly.
class ExtractedMetadata {
  const ExtractedMetadata({
    required this.title,
    required this.artist,
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
  final String? album;
  final int? trackNumber;
  final int? discNumber;
  final Duration duration;
  final List<String> genres;
  final int? year;

  /// Raw bytes of the first embedded picture, if any — NOT resized
  /// yet. Resizing is [SongMetadataReader.cacheCoverArt]'s job,
  /// called separately so this class stays a pure "what does the file
  /// say" reader with no filesystem writes of its own.
  final Uint8List? coverArtBytes;
}

/// Wraps audio_metadata_reader (tags) and the `image` package (cover
/// resize) so neither third-party API leaks past this file.
///
/// KNOWN LIMITATION, deliberate: audio_metadata_reader's condensed
/// metadata type exposes a single `artist` field, not a separate
/// album-artist tag. Until that's confirmed available — or this app
/// parses TPE2/ALBUMARTIST frames itself via the library's
/// format-specific `readAllMetadata` — every indexed [Song] has
/// `albumArtistId == null`. Domain already models this field as
/// nullable for exactly this kind of real-world gap (see
/// [Song.albumArtistId]'s own docstring), so nothing breaks; it's
/// simply not populated yet.
class SongMetadataReader {
  const SongMetadataReader();

  static const _coverArtSize = 512;

  Future<ExtractedMetadata> read(File file) async {
    // `await` here is deliberate even if readMetadata turns out to be
    // synchronous in this version — awaiting a non-Future value is
    // legal Dart and just resolves immediately, so this line is safe
    // either way.
    final metadata = reader.readMetadata(file, getImage: true);

    Uint8List? coverBytes;
    if (metadata.pictures.isNotEmpty) {
      coverBytes = metadata.pictures.first.bytes;
    }

    return ExtractedMetadata(
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      // Some files carry no duration tag; Song.duration is
      // non-nullable, so this is the one place that decides the
      // fallback — zero, never a guessed "real" length.
      duration: metadata.duration ?? Duration.zero,
      genres: metadata.genres,
      year: metadata.year?.year,
      coverArtBytes: coverBytes,
    );
  }

  /// Resizes [coverBytes] to 512x512 and caches it under
  /// [cacheDirectory] — PARTE A's "redimensionar a 512x512 en Isolate
  /// al indexar, NUNCA cargar la original en memoria" satisfied at
  /// the Data layer: the original embedded bytes are decoded once,
  /// here, and never touched again at playback time — only this
  /// already-small cached file is.
  Future<String?> cacheCoverArt({
    required Uint8List coverBytes,
    required String cacheDirectory,
    required String songId,
  }) async {
    final decoded = img.decodeImage(coverBytes);
    if (decoded == null) return null; // corrupt/unsupported embedded image

    final resized = img.copyResize(
      decoded,
      width: _coverArtSize,
      height: _coverArtSize,
      interpolation: img.Interpolation.cubic,
    );

    final outPath = p.join(cacheDirectory, '$songId.jpg');
    await Directory(cacheDirectory).create(recursive: true);
    await File(outPath).writeAsBytes(img.encodeJpg(resized, quality: 85));
    return outPath;
  }
}
