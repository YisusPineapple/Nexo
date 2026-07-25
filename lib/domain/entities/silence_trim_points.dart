/// Detected silence boundaries for a Song, computed once during
/// indexing (see the future `AnalyzeSilenceUseCase`) and cached so the
/// playback engine never re-analyzes audio at play time.
///
/// Only *true* digital silence is trimmed. A quiet instrumental
/// passage or a dramatic pause has non-zero amplitude and is left
/// untouched, even where a naive fixed-threshold trimmer would have
/// cut into it.
final class SilenceTrimPoints {
  const SilenceTrimPoints({
    required this.leadingSilenceMs,
    required this.trailingSilenceMs,
  });

  /// Milliseconds of true silence at the very start of the file.
  final int leadingSilenceMs;

  /// Milliseconds of true silence at the very end of the file.
  final int trailingSilenceMs;

  static const SilenceTrimPoints none = SilenceTrimPoints(
    leadingSilenceMs: 0,
    trailingSilenceMs: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilenceTrimPoints &&
          other.leadingSilenceMs == leadingSilenceMs &&
          other.trailingSilenceMs == trailingSilenceMs);

  @override
  int get hashCode => Object.hash(leadingSilenceMs, trailingSilenceMs);
}