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