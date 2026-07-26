import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

/// Common shape for every Domain use case: a single callable operation
/// taking [P] and returning a [Result]. Kept intentionally tiny — this
/// is a contract, not a place for shared logic, since use cases in
/// this app deliberately don't depend on each other (only on
/// repository interfaces), so there's nothing to factor into a base
/// class body.
abstract interface class UseCase<T, P> {
  Future<Result<T, Failure>> call(P params);
}

/// Marker params type for use cases that take no input (e.g.
/// RestoreSessionUseCase), so each no-arg use case doesn't invent its
/// own empty params type.
final class NoParams {
  const NoParams();
}