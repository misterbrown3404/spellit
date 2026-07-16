import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';
import '../errors/error_classifier.dart';

enum AppLogLevel {
  verbose,
  info,
  warning,
  error,
}

class AppLogger {
  const AppLogger._();

  static void verbose(String message, {Map<String, Object?> context = const {}}) {
    if (kDebugMode) {
      _write(AppLogLevel.verbose, message, context: context);
    }
  }

  static void info(String message, {Map<String, Object?> context = const {}}) {
    if (kDebugMode) {
      _write(AppLogLevel.info, message, context: context);
    }
  }

  static void warning(
    String message, {
    Map<String, Object?> context = const {},
  }) {
    _write(AppLogLevel.warning, message, context: context);
  }

  static void error(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
    Map<String, Object?> context = const {},
  }) {
    final appError = ErrorClassifier.classify(error, stackTrace);
    _write(
      AppLogLevel.error,
      operation == null
          ? appError.developerMessage
          : '$operation failed: ${appError.developerMessage}',
      context: {
        'category': appError.category.name,
        if (appError.code != null) 'code': appError.code,
        ...context,
      },
    );

    if (kDebugMode && appError.stackTrace != null) {
      debugPrint(appError.stackTrace.toString());
    }
  }

  static String sanitize(Object? value) {
    if (value == null) return 'null';
    if (value is AppError) return value.toString();

    final text = value.toString().trim();
    if (text.isEmpty) return '';
    if (text.length <= 8) return text;

    final prefix = text.substring(0, 2);
    final suffix = text.substring(text.length - 2);
    return '$prefix***$suffix';
  }

  static void _write(
    AppLogLevel level,
    String message, {
    Map<String, Object?> context = const {},
  }) {
    final contextText = context.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${sanitize(entry.value)}')
        .join(' ');
    final suffix = contextText.isEmpty ? '' : ' $contextText';
    debugPrint('[${level.name.toUpperCase()}] $message$suffix');
  }
}

