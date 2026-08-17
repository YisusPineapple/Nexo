/// A single line of synchronized lyrics with its timestamp.
/// Used for LRC (lyrics) files and embedded lyrics tags.
class LyricLine {
  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  /// The time offset from the start of the track.
  final Duration timestamp;
  /// The lyric text for this line.
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricLine && other.timestamp == timestamp && other.text == text);

  @override
  int get hashCode => Object.hash(timestamp, text);
}
