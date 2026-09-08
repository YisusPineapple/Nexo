import 'result.dart';
import '../error/failures.dart';

/// Extension to unify how Results are unwrapped into Riverpod's AsyncValue.
/// Addresses Code Smell 2.3 from the architectural audit.
extension ResultToAsync<T, F extends Failure> on Result<T, F> {
  /// Unwraps the success value or throws the Failure.
  /// Designed to be used inside Riverpod's FutureProvider or AsyncNotifier build methods,
  /// which automatically catch thrown exceptions and convert them to AsyncError.
  T unwrapOrThrow() => when(
        ok: (v) => v,
        err: (e) => throw e,
      );
}
