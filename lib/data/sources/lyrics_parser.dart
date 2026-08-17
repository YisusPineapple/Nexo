import '../../domain/entities/lyric_line.dart';
import '../../domain/entities/lyric_segment.dart';

/// Parser for standard LRC and Enhanced LRC (word/syllable) files.
/// Supports 1, 2, or 3-digit millisecond timestamps in `[mm:ss.xxx]` and `<mm:ss.xxx>`.
/// Completely cleans speaker tags like 'v1:', 'male:', '[v1]' without damaging timestamp brackets.
class LyricsParser {
  const LyricsParser._();

  // Matches timestamps like [00:15.324], [00:15.32], [00:15], <00:15.324>, etc.
  static final RegExp _timestampRegex = RegExp(
    r'(?:\[|<)(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?(?:\]|>)',
  );

  // Matches metadata headers like [ti:Title], [ar:Artist], [al:Album], [length:...]
  static final RegExp _metadataRegex = RegExp(
    r'^\[(ti|ar|al|au|by|offset|re|ve|length|kana):',
    caseSensitive: false,
  );

  // Matches voice/speaker tags like 'v1:', 'v2:', '[v1]', 'male:', 'female:', 'c1:', etc.
  static final RegExp _speakerPrefixRegex = RegExp(
    r'^(?:\[(?:v\d+|c\d+|male|female|duet|f|m|vox|voice\s*\d*)\]|\b(?:v\d+|c\d+|male|female|duet|vox|voice\s*\d*)\b[:.]?)\s*',
    caseSensitive: false,
  );

  static String _cleanText(String text) {
    return text.replaceFirst(_speakerPrefixRegex, '').trim();
  }

  /// Parses the raw string content of an LRC file into structured [LyricLine]s.
  static List<LyricLine> parse(String content) {
    final lines = <LyricLine>[];

    for (final rawLine in content.split('\n')) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;
      if (_metadataRegex.hasMatch(trimmed)) continue;

      final matches = _timestampRegex.allMatches(trimmed).toList();
      if (matches.isEmpty) continue;

      final lineTimestamp = _durationFromMatch(matches.first);
      final segments = <LyricSegment>[];

      if (matches.length == 1) {
        final rawText = trimmed.substring(matches.first.end);
        final text = _cleanText(rawText);
        if (text.isNotEmpty) {
          segments.add(LyricSegment(timestamp: lineTimestamp, text: text));
          lines.add(LyricLine(
            lineTimestamp: lineTimestamp,
            segments: segments,
            text: text,
          ));
        }
        continue;
      }

      // Enhanced LRC with multiple inline segment timestamps
      var cursor = matches.first.end;
      var currentSegmentTimestamp = lineTimestamp;

      for (var i = 1; i < matches.length; i++) {
        final match = matches[i];
        final rawTextBefore = trimmed.substring(cursor, match.start);
        final textBefore = _cleanText(rawTextBefore);
        if (textBefore.isNotEmpty) {
          segments.add(LyricSegment(
            timestamp: currentSegmentTimestamp,
            text: textBefore,
          ));
        }
        currentSegmentTimestamp = _durationFromMatch(match);
        cursor = match.end;
      }

      final rawTrailingText = trimmed.substring(cursor);
      final trailingText = _cleanText(rawTrailingText);
      if (trailingText.isNotEmpty) {
        segments.add(LyricSegment(
          timestamp: currentSegmentTimestamp,
          text: trailingText,
        ));
      }

      if (segments.isNotEmpty) {
        lines.add(LyricLine(
          lineTimestamp: lineTimestamp,
          segments: segments,
        ));
      }
    }

    lines.sort((a, b) => a.lineTimestamp.compareTo(b.lineTimestamp));
    return lines;
  }

  static Duration _durationFromMatch(Match match) {
    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final millisRaw = match.group(3) ?? '0';
    final millis = int.parse(millisRaw.padRight(3, '0').substring(0, 3));

    return Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: millis,
    );
  }
}