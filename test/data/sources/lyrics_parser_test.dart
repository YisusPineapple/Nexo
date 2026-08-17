import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/data/sources/lyrics_parser.dart';
import 'package:nexo/domain/entities/lyric_line.dart';

void main() {
  group('LyricsParser', () {
    test('parses single timestamp line', () {
      final content = '[00:10.50]Hello world';
      final lines = LyricsParser.parse(content);
      expect(lines.length, 1);
      expect(lines.first, LyricLine(timestamp: const Duration(minutes: 0, seconds: 10, milliseconds: 500), text: 'Hello world'));
    });

    test('parses multiple timestamps on same line using first timestamp', () {
      final content = '[00:05.00][00:10.00]Repeat line';
      final lines = LyricsParser.parse(content);
      expect(lines.length, 1);
      expect(lines.first.timestamp, const Duration(seconds: 5));
      expect(lines.first.text, 'Repeat line');
    });

    test('ignores metadata tags and empty lines', () {
      final content = '''
[ti:Title]

[ar:Artist]
[00:20]Line after metadata

''';
      final lines = LyricsParser.parse(content);
      expect(lines.length, 1);
      expect(lines.first.timestamp, const Duration(seconds: 20));
      expect(lines.first.text, 'Line after metadata');
    });

    test('sorts unsorted timestamps', () {
      final content = '[00:30]Last\n[00:10]First\n[00:20]Middle';
      final lines = LyricsParser.parse(content);
      expect(lines.length, 3);
      expect(lines.map((l) => l.timestamp).toList(), [const Duration(seconds: 10), const Duration(seconds: 20), const Duration(seconds: 30)]);
    });
  });
}
