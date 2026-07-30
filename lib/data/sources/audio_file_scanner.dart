import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/audio_format.dart';

/// Recursive directory scanner mapping file extensions to
/// [AudioFormat] — the "which files does Nexo even know how to play"
/// gate, run BEFORE any metadata parsing is attempted.
class AudioFileScanner {
  const AudioFileScanner();

  static const _extensionToFormat = <String, AudioFormat>{
    '.mp3': AudioFormat.mp3,
    '.m4a': AudioFormat.aac,
    '.aac': AudioFormat.aac,
    '.flac': AudioFormat.flac,
    '.opus': AudioFormat.opus,
    '.ogg': AudioFormat.vorbis,
    '.oga': AudioFormat.vorbis,
    '.wav': AudioFormat.wav,
    '.wma': AudioFormat.wma,
    '.aiff': AudioFormat.aiff,
    '.aif': AudioFormat.aiff,
    '.eac3': AudioFormat.eac3,
    '.ec3': AudioFormat.eac3,
    '.ac4': AudioFormat.ac4,
    '.webm': AudioFormat.webm,
  };

  /// Recursively lists every file under [directoryPath] whose
  /// extension maps to a supported [AudioFormat]. Unsupported files
  /// (playlists, images, anything else) are silently skipped.
  /// Returns an empty list — not a [Failure] — for a directory that
  /// doesn't exist, matching this app's general resilience posture
  /// (a stale/removed watched folder is a normal state, not an error).
  Future<List<(String path, AudioFormat format)>> scan(
    String directoryPath,
  ) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return const [];

    final results = <(String, AudioFormat)>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final format = formatForPath(entity.path);
      if (format != null) results.add((entity.path, format));
    }
    return results;
  }

  /// Exposed separately from [scan] so a single path can be checked
  /// (and tested) without touching the filesystem at all.
  AudioFormat? formatForPath(String path) {
    return _extensionToFormat[p.extension(path).toLowerCase()];
  }
}
