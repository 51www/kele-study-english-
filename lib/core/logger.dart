import 'package:flutter/foundation.dart';

/// 统一日志入口：所有日志必须经过脱敏，禁止输出 Key / Authorization / 完整转写。
class AppLogger {
  AppLogger._();

  static final List<String> _buffer = [];
  static bool enabled = true;

  static List<String> get buffer => List.unmodifiable(_buffer);

  static String redact(String input) {
    var out = input;
    out = out.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9._\-]+', caseSensitive: false),
      'Bearer ***',
    );
    out = out.replaceAll(
      RegExp(r'(api[_-]?key"?\s*[:=]\s*"?)[^"\s,}]+', caseSensitive: false),
      r'$1***',
    );
    out = out.replaceAll(
      RegExp(r'(authorization"?\s*[:=]\s*"?)[^"\s,}]+', caseSensitive: false),
      r'$1***',
    );
    out = out.replaceAll(RegExp(r'sk-[A-Za-z0-9._\-]+'), 'sk-***');
    out = out.replaceAll(RegExp(r'QC-[A-Za-z0-9._\-]+'), 'QC-***');
    return out;
  }

  static void debug(String message) {
    if (!enabled) return;
    final line = '[${DateTime.now().toIso8601String()}] ${redact(message)}';
    _buffer.add(line);
    if (_buffer.length > 300) _buffer.removeAt(0);
    if (kDebugMode) {
      // ignore: avoid_print
      print(line);
    }
  }

  static void warn(String message) => debug('WARN $message');

  static void error(String message, [Object? error, StackTrace? stack]) {
    debug('ERROR $message ${error ?? ''}');
    if (stack != null && kDebugMode) {
      // 只保留首行，避免大段堆栈进入普通日志。
      final firstLine = stack.toString().split('\n').first;
      debug('STACK $firstLine');
    }
  }

  static void clear() => _buffer.clear();
}
