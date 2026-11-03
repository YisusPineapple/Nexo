import 'dart:async';

/// A tiny FIFO serializer for async tasks.
///
/// Used to guarantee that rapid successive calls to an async handler
/// (e.g. `onQueueAdvanced` firing twice when the user presses Next
/// quickly) run one after another, never concurrently. Without this,
/// two handlers can read the same stale state, compute the same next
/// value, and the second can overwrite the first — losing a user action.
///
/// The class is intentionally standalone so it can be tested without
/// any of the surrounding Riverpod / audio-handler machinery.
///
/// Failure semantics: a task that throws does NOT poison the chain.
/// The caller of [enqueue] receives the error on the returned Future,
/// but the internal `_chain` is always left in a successful state so
/// that subsequent tasks still run. Without this, one transient
/// `saveQueue` failure would freeze every future `onQueueAdvanced`
/// call until the app restarts.
final class SerializedTaskQueue {
  Future<void> _chain = Future<void>.value();

  /// Enqueues [task]. Returns a Future that completes when [task] runs
  /// and completes, or errors with the same error [task] threw.
  ///
  /// If a previous task is still in flight, [task] waits for it. A
  /// failure in a previous task does not prevent this one from running.
  Future<void> enqueue(Future<void> Function() task) {
    final result = Completer<void>();
    _chain = _chain.then((_) async {
      try {
        await task();
        if (!result.isCompleted) {
          result.complete();
        }
      } catch (e, st) {
        if (!result.isCompleted) {
          result.completeError(e, st);
        }
      }
    });
    return result.future;
  }
}
