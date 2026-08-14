import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/entities/audio_format.dart';

/// Recursive directory scanner mapping file extensions to
/// [AudioFormat].
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
  /// extension maps to a supported [AudioFormat].
  /// 
  /// PERFORMANCE: Uses manual recursion instead of `dir.list(recursive: true)`
  /// to check [excludedPaths] BEFORE entering a subdirectory. This prevents
  /// the OS from doing expensive `stat()` calls and disk reads on ignored
  /// folders (e.g., Podcasts, Audiobooks), which is critical for HDDs.
  Future<List<(String path, AudioFormat format)>> scan(
    String directoryPath, {
    Set<String> excludedPaths = const {},
  }) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return const [];
    
    final results = <(String, AudioFormat)>[];
    await _scanRecursive(dir, excludedPaths, results);
    return results;
  }

  Future<void> _scanRecursive(
    Directory dir,
    Set<String> excludedPaths,
    List<(String, AudioFormat)> results,
  ) async {
    // Check if current directory is explicitly excluded
    if (excludedPaths.contains(dir.path)) return;

    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is Directory) {
        await _scanRecursive(entity, excludedPaths, results);
      } else if (entity is File) {
        final format = formatForPath(entity.path);
        if (format != null) results.add((entity.path, format));
      }
    }
  }

  AudioFormat? formatForPath(String path) {
    return _extensionToFormat[p.extension(path).toLowerCase()];
  }
}