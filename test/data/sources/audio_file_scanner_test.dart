import 'dart:io';

import 'package:test/test.dart';

import 'package:nexo/data/sources/audio_file_scanner.dart';
import 'package:nexo/domain/entities/audio_format.dart';

void main() {
  group('AudioFileScanner', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nexo_scanner_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('finds supported files recursively and skips unsupported ones',
        () async {
      await File('${tempDir.path}/track.mp3').create();
      await File('${tempDir.path}/cover.jpg').create(); // unsupported
      final nested = Directory('${tempDir.path}/album')..createSync();
      await File('${nested.path}/song.flac').create();

      const scanner = AudioFileScanner();
      final found = await scanner.scan(tempDir.path);

      expect(found.length, 2);
      expect(
        found.map((r) => r.$2),
        containsAll([AudioFormat.mp3, AudioFormat.flac]),
      );
    });

    test('formatForPath is case-insensitive on extension', () {
      const scanner = AudioFileScanner();
      expect(scanner.formatForPath('/x/Track.MP3'), AudioFormat.mp3);
    });

    test('returns an empty list for a non-existent directory', () async {
      const scanner = AudioFileScanner();
      final found = await scanner.scan('${tempDir.path}/does-not-exist');
      expect(found, isEmpty);
    });
  });
}
