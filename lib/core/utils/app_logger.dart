import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  static bool get enabled => kDebugMode;

  static void d(
    String message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(message, tag: tag, level: 500, error: error, stackTrace: stackTrace);
  }

  static void i(
    String message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(message, tag: tag, level: 800, error: error, stackTrace: stackTrace);
  }

  static void w(
    String message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(message, tag: tag, level: 900, error: error, stackTrace: stackTrace);
  }

  static void e(
    String message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(message, tag: tag, level: 1000, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String message, {
    required String tag,
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;
    developer.log(message, name: tag, level: level, error: error, stackTrace: stackTrace);
  }
}

