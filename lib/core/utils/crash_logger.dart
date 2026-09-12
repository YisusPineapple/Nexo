import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class CrashLogger {
  const CrashLogger._();

  static late final File _logFile;
  static const int _maxLogSize = 2 * 1024 * 1024; // 2 MB

  static void init(String supportDirPath) {
    _logFile = File(p.join(supportDirPath, 'nexo_crash.log'));

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logError('FlutterError', details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('PlatformDispatcher', error, stack);
      return true;
    };
  }

  static void _logError(String type, Object error, StackTrace? stack) {
    try {
      if (_logFile.existsSync() && _logFile.lengthSync() > _maxLogSize) {
        _logFile.writeAsStringSync('--- LOG ROTATED ---\n');
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final logEntry = '[$timestamp] [$type]\n$error\n$stack\n\n';

      _logFile.writeAsStringSync(logEntry, mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write crash log: $e');
    }
  }

  /// Writes an informational line to the crash log. Unlike [_logError],
  /// this never throws: a failure to log must never abort the caller, and
  /// one caller is the schema 15 migration — throwing there would abort
  /// the transaction and brick the app on every subsequent launch.
  ///
  /// Note: [_logFile] is `static late final` and is only initialized by
  /// [init]. In the current bootstrap order `init` always runs before any
  /// migration, but that ordering is implicit and not guaranteed by
  /// anything in the type system. The try below wraps the [_logFile] access
  /// itself, not only the write, so a `LateInitializationError` is
  /// swallowed like any other failure.
  ///
  /// No rotation is performed here — this method is for one-off
  /// informational events (like a migration counting dropped rows), not
  /// for high-frequency error logging. Rotation remains the responsibility
  /// of [_logError].
  static void logEvent(String category, String message) {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      _logFile.writeAsStringSync(
        '[$timestamp] [$category] $message\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Intentionally swallowed. See docstring.
    }
  }

  static Future<String> readLog() async {
    try {
      if (await _logFile.exists()) {
        return await _logFile.readAsString();
      }
      return 'No crash logs found. The app is running smoothly!';
    } catch (e) {
      return 'Error reading crash log: $e';
    }
  }

  static Future<void> clearLog() async {
    try {
      if (await _logFile.exists()) {
        await _logFile.delete();
      }
    } catch (e) {
      debugPrint('Failed to clear crash log: $e');
    }
  }
}
