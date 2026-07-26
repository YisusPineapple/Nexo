// Base type for all recoverable domain-level errors. Deliberately kept
// small: new subtypes are added per feature area as their use cases
// are implemented, instead of front-loading a giant enum that would
// force every phase to touch this file.

sealed class Failure {
  const Failure(this.message);

  /// Diagnostic message for logs/tests. Presentation maps this to a
  /// localized, user-facing string — this is NOT shown directly in UI.
  final String message;
}

/// A value object or entity failed its own invariant check (e.g.
/// crossfade duration out of the 0-12s range).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// An unclassified error surfaced from outside the Domain layer (data
/// sources, platform channels, etc.), passed through as-is so the
/// original diagnostic detail isn't lost.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {this.cause});
  final Object? cause;
}

/// A lookup by identifier (Song, PlaybackQueue, etc.) found no match.
/// Distinct from [ValidationFailure]: the caller's input was well-formed,
/// the record simply isn't there — e.g. a Song referenced by a stale
/// playlist entry after the underlying file was removed and re-scanned
/// away. Kept as its own type (rather than reusing UnexpectedFailure) so
/// use cases can pattern-match on it and react differently — a missing
/// song is often recoverable UI-side (skip it, mark it stale), whereas
/// an UnexpectedFailure usually isn't.
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Why a [PlaybackFailure] happened, so the layer that catches it can
/// decide how to react without parsing [Failure.message].
enum PlaybackFailureReason {
  /// The engine could not decode this specific file (corrupt data,
  /// unsupported codec variant within an otherwise-supported
  /// container). Per the RESILIENCIA requirement, the use case that
  /// observes this reason reacts by auto-advancing to the next track —
  /// it must NEVER halt playback outright on a single bad file.
  decodeError,

  /// A native-player/platform-channel error unrelated to decoding a
  /// specific file (e.g. the output device disappeared, audio focus
  /// was lost unexpectedly). Auto-advancing to the next track is NOT
  /// the right reaction here — the same failure would likely repeat
  /// immediately on the next song too.
  engineError,
}

/// An error surfaced by the audio engine during playback, as opposed to
/// [UnexpectedFailure]'s broader "something outside Domain went wrong".
/// Carrying [reason] explicitly (rather than folding this into
/// UnexpectedFailure with a string message) is what lets the future
/// playback use case implement the RESILIENCIA "skip to next track on
/// decode error" rule without string-matching on [Failure.message].
final class PlaybackFailure extends Failure {
  const PlaybackFailure(super.message, {required this.reason, this.cause});

  final PlaybackFailureReason reason;
  final Object? cause;
}