import 'package:test/test.dart';
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
}