import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Ok exposes value and isOk/isErr correctly', () {
      const result = Ok<int, String>(42);
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
    });

    test('Err exposes error and isOk/isErr correctly', () {
      const result = Err<int, String>('failed');
      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
    });

    test('when() dispatches to the matching branch', () {
      const ok = Ok<int, String>(10);
      const err = Err<int, String>('boom');

      expect(ok.when(ok: (v) => v * 2, err: (_) => -1), 20);
      expect(err.when(ok: (v) => v * 2, err: (_) => -1), -1);
    });

    test('map() transforms only the success branch', () {
      const ok = Ok<int, String>(2);
      const err = Err<int, String>('boom');

      expect(ok.map((v) => v + 1), const Ok<int, String>(3));
      expect(err.map((v) => v + 1), const Err<int, String>('boom'));
    });
  });

  group('Result.asyncAndThen', () {
    test('runs transform and returns its result for Ok', () async {
      const ok = Ok<int, String>(2);
      final result = await ok.asyncAndThen(
        (v) async => Ok<int, String>(v + 1),
      );
      expect(result, const Ok<int, String>(3));
    });

    test(
        'short-circuits to the existing error for Err without running '
        'transform', () async {
      const err = Err<int, String>('boom');
      var transformCalled = false;
      final result = await err.asyncAndThen((v) async {
        transformCalled = true;
        return Ok<int, String>(v + 1);
      });
      expect(result, const Err<int, String>('boom'));
      expect(transformCalled, isFalse);
    });
  });
}
