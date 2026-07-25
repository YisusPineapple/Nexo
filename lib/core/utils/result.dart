// Domain layer must not depend on external FP packages (fpdart, dartz,
// etc.), so this file provides a minimal, dependency-free Either-style
// Result type using Dart 3 sealed classes and pattern matching. Every
// repository and use case in the app returns `Result<T, Failure>`
// instead of throwing, making every possible failure explicit in the
// method signature.

sealed class Result<T, F> {
  const Result();

  /// Forces callers to handle both branches; there is no way to read
  /// [T] out of a [Result] without acknowledging the [F] case exists.
  R when<R>({
    required R Function(T value) ok,
    required R Function(F error) err,
  }) {
    return switch (this) {
      Ok<T, F>(value: final v) => ok(v),
      Err<T, F>(error: final e) => err(e),
    };
  }

  /// Transforms the success value, leaving an [Err] untouched. Useful
  /// for chaining repository calls inside use cases without nested
  /// when()s.
  Result<R, F> map<R>(R Function(T value) transform) {
    return switch (this) {
      Ok<T, F>(value: final v) => Ok(transform(v)),
      Err<T, F>(error: final e) => Err(e),
    };
  }

  bool get isOk => this is Ok<T, F>;
  bool get isErr => this is Err<T, F>;

  /// Escape hatch for call sites (mostly Presentation) that only care
  /// whether a value exists, e.g. to decide whether to show a snackbar.
  T? get valueOrNull => switch (this) {
        Ok<T, F>(value: final v) => v,
        Err<T, F>() => null,
      };
}

final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T, F> && other.value == value);

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class Err<T, F> extends Result<T, F> {
  const Err(this.error);
  final F error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T, F> && other.error == error);

  @override
  int get hashCode => Object.hash(runtimeType, error);
}