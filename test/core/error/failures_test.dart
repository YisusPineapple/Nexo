import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/core/error/failures.dart';

void main() {
  group('NotFoundFailure', () {
    test('carries the diagnostic message', () {
      const failure = NotFoundFailure('No song found with id "s1".');
      expect(failure.message, 'No song found with id "s1".');
    });
  });

  group('PlaybackFailure', () {
    test('carries a reason distinguishing decode from engine errors', () {
      const failure = PlaybackFailure(
        'Could not decode track.',
        reason: PlaybackFailureReason.decodeError,
      );
      expect(failure.reason, PlaybackFailureReason.decodeError);
    });

    test('optionally carries the underlying cause', () {
      final cause = Exception('native decoder crashed');
      final failure = PlaybackFailure(
        'Engine reported an error.',
        reason: PlaybackFailureReason.engineError,
        cause: cause,
      );
      expect(failure.cause, cause);
    });
  });
}
