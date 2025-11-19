import 'dart:async';

import 'package:telegram_crash_reporter/telegram_crash_reporter.dart';

class TelegramReporter {
  static bool _initialized = false;

  /// Initialize Telegram crash reporter with given bot token and chat id.
  static Future<void> init({required String botToken, required int chatId}) async {
    if (_initialized) return;
    try {
      // The package's initialize is likely a synchronous call (void return), so we don't await it.
      TelegramCrashReporter.initialize(botToken: botToken, chatId: chatId);
      _initialized = true;
    } catch (e) {
      // ignore: avoid_print
      print('TelegramReporter.init failed: $e');
    }
  }

  /// Send a simple text log to Telegram.
  static Future<void> sendLog(String message) async {
    if (!_initialized) {
      // ignore: avoid_print
      print(message);
      return;
    }
    try {
      // Use reportCrash to send a log message (non-fatal) since the package may not have a dedicated "sendMessage" API.
      TelegramCrashReporter.reportCrash(
        error: message,
        stackTrace: StackTrace.current,
        context: 'Log',
        fatal: false,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send log to Telegram: $e');
    }
  }

  /// Report an error/exception with an optional stack trace and context.
  static Future<void> reportError(Object error, [StackTrace? stackTrace, Map<String, Object?>? extra, String? context, bool fatal = false]) async {
    if (!_initialized) {
      // ignore: avoid_print
      print('Error: $error');
      if (stackTrace != null) {
        // ignore: avoid_print
        print(stackTrace);
      }
      return;
    }
    try {
      TelegramCrashReporter.reportCrash(
        error: error,
        stackTrace: stackTrace ?? StackTrace.current,
        context: context ?? (extra?.toString() ?? 'Error'),
        fatal: fatal,
        extraData: extra ?? {},
      );
    } catch (e) {
      // ignore: avoid_print
      print('Failed to report error to Telegram: $e');
    }
  }
}
