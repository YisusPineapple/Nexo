import '../../domain/entities/lyric_line.dart';
import '../../domain/entities/lyric_segment.dart';

/// Parser for standard and Enhanced `.lrc` files.
/// Supports timestamps in the format `[mm:ss.xx]` or `[mm:ss]`, and also
/// enhanced-lrc word/syllable timestamps wrapped in angle brackets, such as
/// `<mm:ss.xx>`.
/// Ignores metadata tags like `[ti:...]`, `[ar:...]`, etc.
class LyricsParser {
  const LyricsParser._();

  // Matches [mm:ss] / [mm:ss.xx] / <mm:ss> / <mm:ss.xx>
  static final RegExp _timestampRegex = RegExp(
    r'(?:\[(\d{2}):(\d{2})(?:\.(\d{2}))?\]|<(\d{2}):(\d{2})(?:\.(\d{2}))?>)',
  );

  /// Parses the content of an LRC file and returns a list of [LyricLine].
  static List<LyricLine> parse(String content) {
    final lines = <LyricLine>[];

    for (final rawLine in content.split('\n')) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final matches = _timestampRegex.allMatches(trimmed).toList();
      if (matches.isEmpty) continue;

      final lineTimestamp = _durationFromMatch(matches.first);
      final segments = <LyricSegment>[];

      if (matches.length == 1) {
        final text = trimmed.substring(matches.first.end).trim();
        if (text.isNotEmpty) {
          segments.add(LyricSegment(timestamp: lineTimestamp, text: text));
        }
        if (segments.isNotEmpty) {
          lines
              .add(LyricLine(lineTimestamp: lineTimestamp, segments: segments));
        }
        continue;
      }

      var cursor = matches.first.end;
      var currentSegmentTimestamp = lineTimestamp;

      for (var i = 1; i < matches.length; i++) {
        final match = matches[i];
        final textBefore = trimmed.substring(cursor, match.start).trimRight();
        if (textBefore.isNotEmpty) {
          segments.add(
            LyricSegment(timestamp: currentSegmentTimestamp, text: textBefore),
          );
        }

        currentSegmentTimestamp = _durationFromMatch(match);
        cursor = match.end;
      }

      final trailingText = trimmed.substring(cursor).trimLeft();
      if (trailingText.isNotEmpty) {
        segments.add(
          LyricSegment(timestamp: currentSegmentTimestamp, text: trailingText),
        );
      }

      if (segments.isNotEmpty) {
        lines.add(
          LyricLine(
            lineTimestamp: lineTimestamp,
            segments: segments,
          ),
        );
      }
    }

    lines.sort((a, b) => a.lineTimestamp.compareTo(b.lineTimestamp));
    return lines;
  }

  static Duration _durationFromMatch(Match match) {
    final minutes = int.parse(match.group(1) ?? match.group(4)!);
    final seconds = int.parse(match.group(2) ?? match.group(5)!);
    final centis = (match.group(3) ?? match.group(6))?.padRight(2, '0') ?? '00';
    final milliseconds = int.parse(centis) * 10;

    return Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
