import '../../domain/entities/lyric_line.dart';

/// Parser for standard `.lrc` files.
/// Supports timestamps in the format `[mm:ss.xx]` or `[mm:ss]`.
/// Ignores metadata tags like `[ti:...]`, `[ar:...]`, etc.
/// Handles multiple timestamps per line (uses the first one).
class LyricsParser {
  const LyricsParser._();

  // Matches [mm:ss] or [mm:ss.xx] – groups: minutes, seconds, optional centiseconds.
  static final RegExp _timestampRegex = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{2}))?\]');

  /// Parses the content of an LRC file and returns a list of [LyricLine].
  static List<LyricLine> parse(String content) {
    final lines = <LyricLine>[];
    for (final rawLine in content.split('\n')) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      // Find consecutive timestamp tags at the start of the line. We
      // will use the first timestamp as the line timestamp, but skip
      // any additional leading tags when extracting the text.
      final iter = _timestampRegex.allMatches(trimmed);
      if (iter.isEmpty) continue;

      // Determine how many consecutive timestamp matches start at 0.
      int lastEnd = 0;
      Match? firstMatch;
      for (final m in iter) {
        if (m.start != lastEnd) break;
        firstMatch ??= m;
        lastEnd = m.end;
      }
      if (firstMatch == null) continue;

      // Extract timestamp components from the first match.
      final minutes = int.parse(firstMatch.group(1)!);
      final seconds = int.parse(firstMatch.group(2)!);
      final centis = firstMatch.group(3)?.padRight(2, '0') ?? '00';
      final milliseconds = int.parse(centis) * 10;

      final timestamp = Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );

      // The text is everything after all leading timestamp tags.
      final text = trimmed.substring(lastEnd).trim();
      if (text.isNotEmpty) {
        lines.add(LyricLine(timestamp: timestamp, text: text));
      }
    }

    // Sort lines by timestamp (some files may have unsorted timestamps).
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }
}
