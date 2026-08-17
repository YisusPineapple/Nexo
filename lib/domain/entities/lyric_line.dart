import 'lyric_segment.dart';

/// A single line of synchronized lyrics.
/// Classical LRC stores one timestamp per line, while Enhanced LRC may split a
/// lyric line into several timestamped segments (word/syllable level).
class LyricLine {
  LyricLine({
    required this.lineTimestamp,
    this.segments = const [],
    String? text,
  }) : text = text ?? _joinSegments(segments);

  /// The first timestamp of the line, used for classic LRC ordering.
  final Duration lineTimestamp;

  /// The timestamped segments that make up this lyric line.
  final List<LyricSegment> segments;

  /// The lyric text for this line.
  final String text;

  /// Backwards-compatible alias for the first timestamp of the line.
  Duration get timestamp => lineTimestamp;

  /// Full concatenated text across all segments.
  String get fullText => segments.map((segment) => segment.text).join(' ');

  static String _joinSegments(List<LyricSegment> segments) {
    return segments.map((segment) => segment.text).join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricLine &&
          other.lineTimestamp == lineTimestamp &&
          other.segments.length == segments.length &&
          other.text == text &&
          _segmentsEqual(other.segments, segments));

  @override
  int get hashCode =>
      Object.hash(lineTimestamp, text, Object.hashAll(segments));

  static bool _segmentsEqual(
      List<LyricSegment> left, List<LyricSegment> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}
