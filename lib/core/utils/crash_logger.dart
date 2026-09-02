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
