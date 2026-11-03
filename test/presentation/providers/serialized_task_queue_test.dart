import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/presentation/providers/serialized_task_queue.dart';

void main() {
  group('SerializedTaskQueue', () {
    test('runs tasks sequentially, waiting for the previous to complete',
        () async {
      final queue = SerializedTaskQueue();
      final log = <String>[];

      final f1 = queue.enqueue(() async {
        log.add('start1');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        log.add('end1');
      });
      final f2 = queue.enqueue(() async {
        log.add('start2');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        log.add('end2');
      });

      await Future.wait([f1, f2]);

      expect(log, ['start1', 'end1', 'start2', 'end2'],
          reason: 'Tasks must run strictly one after another. If "start2" '
              'appeared before "end1", the queue would not be serializing, '
              'and onQueueAdvanced would lose skips in production.');
    });

    test('a failing task does not prevent subsequent tasks from running',
        () async {
      final queue = SerializedTaskQueue();
      final log = <String>[];

      final f1 = queue.enqueue(() async {
        log.add('bad-start');
        throw StateError('boom');
      });
      final f2 = queue.enqueue(() async {
        log.add('good');
      });

      // f1 completes with an error; swallow it explicitly.
      await f1.catchError((_) {});
      await f2;

      expect(log, contains('good'),
          reason: 'A failed task must not poison the chain. Future tasks '
              'still run — otherwise one corrupt saveQueue call would '
              'freeze the queue forever.');
    });

    test('the returned Future completes with the task result', () async {
      final queue = SerializedTaskQueue();
      var ran = false;
      await queue.enqueue(() async {
        ran = true;
      });
      expect(ran, isTrue);
    });
  });
}