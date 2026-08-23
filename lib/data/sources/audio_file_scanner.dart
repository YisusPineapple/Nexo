import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/audio_format.dart';

class AudioFileScanner {
  const AudioFileScanner();

  static const _extensionToFormat = <String, AudioFormat>{
    '.mp3': AudioFormat.mp3, '.m4a': AudioFormat.aac, '.aac': AudioFormat.aac,
    '.flac': AudioFormat.flac, '.opus': AudioFormat.opus, '.ogg': AudioFormat.vorbis,
    '.oga': AudioFormat.vorbis, '.wav': AudioFormat.wav, '.wma': AudioFormat.wma,
    '.aiff': AudioFormat.aiff, '.aif': AudioFormat.aiff, '.eac3': AudioFormat.eac3,
    '.ec3': AudioFormat.eac3, '.ac4': AudioFormat.ac4, '.webm': AudioFormat.webm,
    '.alac': AudioFormat.aac, '.m4b': AudioFormat.aac, '.mp4': AudioFormat.aac,
    '.ape': AudioFormat.wav, '.dsf': AudioFormat.wav, '.m4v': AudioFormat.aac,
  };

  Future<List<(String path, AudioFormat format)>> scan(
    String directoryPath, {
    Set<String> excludedPaths = const {},
  }) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return const [];
    
    final results = <(String, AudioFormat)>[];
    final visited = <String>{};
    
    await _scanRecursive(dir, excludedPaths, results, visited);
    return results;
  }

  Future<void> _scanRecursive(
    Directory dir,
    Set<String> excludedPaths,
    List<(String, AudioFormat)> results,
    Set<String> visited,
  ) async {
    if (excludedPaths.contains(dir.path)) return;

    try {
      final canonicalPath = dir.resolveSymbolicLinksSync();
      if (visited.contains(canonicalPath)) return;
      visited.add(canonicalPath);

      await for (final entity in dir.list(recursive: false, followLinks: true)) {
        if (entity is Directory) {
          await _scanRecursive(entity, excludedPaths, results, visited);
        } else if (entity is File) {
          // FIX: Normalize and absolute the path to prevent duplicates on Linux/Windows
          // where paths might have trailing slashes or different casing.
          final normalizedPath = p.normalize(p.absolute(entity.path));
          final format = formatForPath(normalizedPath);
          if (format != null) results.add((normalizedPath, format));
        }
      }
    } catch (e) {
      debugPrint('Skipping directory ${dir.path} due to error: $e');
    }
  }

  AudioFormat? formatForPath(String path) {
    return _extensionToFormat[p.extension(path).toLowerCase()];
  }
}