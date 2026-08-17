/// A single timestamped chunk inside an LRC line.
/// Enhanced LRC may split a line into multiple segments, each with its own
/// timestamp (e.g. word or syllable-level highlighting).
class LyricSegment {
  const LyricSegment({
    required this.timestamp,
    required this.text,
  });

  final Duration timestamp;
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricSegment &&
          other.timestamp == timestamp &&
          other.text == text);

  @override
  int get hashCode => Object.hash(timestamp, text);
}
