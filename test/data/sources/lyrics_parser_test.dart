import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/data/sources/lyrics_parser.dart';
import 'package:nexo/domain/entities/lyric_segment.dart';

void main() {
  group('LyricsParser', () {
    test('parses a classic LRC line', () {
      final content = '[00:10.50]Hello world';
      final lines = LyricsParser.parse(content);

      expect(lines.length, 1);
      expect(lines.first.lineTimestamp, const Duration(seconds: 10, milliseconds: 500));
      expect(lines.first.segments, [
        const LyricSegment(
          timestamp: Duration(seconds: 10, milliseconds: 500),
          text: 'Hello world',
        ),
      ]);
      expect(lines.first.fullText, 'Hello world');
    });

    test('parses enhanced LRC word-level segments', () {
      final content = '[00:05.00]Hello <00:06.50>world <00:08.00>again';
      final lines = LyricsParser.parse(content);

      expect(lines.length, 1);
      expect(lines.first.lineTimestamp, const Duration(seconds: 5));
      expect(lines.first.segments, [
        const LyricSegment(timestamp: Duration(seconds: 5), text: 'Hello'),
        const LyricSegment(timestamp: Duration(seconds: 6, milliseconds: 500), text: 'world'),
        const LyricSegment(timestamp: Duration(seconds: 8), text: 'again'),
      ]);
      expect(lines.first.fullText, 'Hello world again');
    });

    test('ignores metadata tags and empty lines', () {
      final content = '''
[ti:Title]

[ar:Artist]
[00:20]Line after metadata

''';
      final lines = LyricsParser.parse(content);
      expect(lines.length, 1);
      expect(lines.first.lineTimestamp, const Duration(seconds: 20));
      expect(lines.first.fullText, 'Line after metadata');
    });

    test('sorts unsorted timestamps', () {
      final content = '[00:30]Last\n[00:10]First\n[00:20]Middle';
      final lines = LyricsParser.parse(content);
      expect(lines.length, 3);
      expect(lines.map((l) => l.lineTimestamp).toList(), [
        const Duration(seconds: 10),
        const Duration(seconds: 20),
        const Duration(seconds: 30),
      ]);
    });
  });
}
