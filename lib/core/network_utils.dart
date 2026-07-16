import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'logging/app_logger.dart';
import 'network/network_exceptions.dart';

typedef NetworkAction<T> = Future<T> Function();

class AppNetwork {
  AppNetwork._();

  static const Duration defaultTimeout = Duration(seconds: 15);
  static const int defaultMaxAttempts = 3;
  static const Duration defaultRetryDelay = Duration(seconds: 2);
  static final Random _random = Random();

  static Future<T> execute<T>({
    required NetworkAction<T> action,
    Duration timeout = defaultTimeout,
    int maxAttempts = defaultMaxAttempts,
    Duration retryDelay = defaultRetryDelay,
    String? operationName,
    bool Function(Object error)? shouldRetry,
  }) async {
    var attempt = 0;

    while (true) {
      attempt++;
      try {
        return await action().timeout(timeout);
      } on TimeoutException catch (error, stackTrace) {
        if (!_shouldRetry(attempt, maxAttempts, error, shouldRetry)) {
          _logFailure(operationName, error, stackTrace);
          rethrow;
        }
        await _waitBeforeRetry(attempt, maxAttempts, retryDelay);
      } on FirebaseException catch (error, stackTrace) {
        if (!_shouldRetry(attempt, maxAttempts, error, shouldRetry)) {
          _logFailure(operationName, error, stackTrace);
          rethrow;
        }
        await _waitBeforeRetry(attempt, maxAttempts, retryDelay);
      } catch (error, stackTrace) {
        if (!_shouldRetry(attempt, maxAttempts, error, shouldRetry)) {
          _logFailure(operationName, error, stackTrace);
          rethrow;
        }
        await _waitBeforeRetry(attempt, maxAttempts, retryDelay);
      }
    }
  }

  static Future<void> _waitBeforeRetry(
    int attempt,
    int maxAttempts,
    Duration retryDelay,
  ) async {
    if (retryDelay > Duration.zero && attempt < maxAttempts) {
      final exponentialDelay = retryDelay * (1 << (attempt - 1));
      final jitter = Duration(milliseconds: _random.nextInt(250));
      await Future.delayed(exponentialDelay + jitter);
    }
  }

  static bool _shouldRetry(
    int attempt,
    int maxAttempts,
    Object error,
    bool Function(Object error)? shouldRetry,
  ) {
    if (attempt >= maxAttempts) {
      return false;
    }

    if (shouldRetry != null) {
      return shouldRetry(error);
    }

    return isNetworkRelatedException(error);
  }

  static bool isNetworkRelatedException(Object error) {
    if (error is TimeoutException) return true;
    if (isSocketLikeException(error)) return true;
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      return code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          code == 'network-request-failed' ||
          code == 'aborted';
    }
    return false;
  }

  static void _logFailure(
    String? operationName,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.error(
      error,
      stackTrace: stackTrace,
      operation: operationName ?? 'request',
    );
  }

  static String sanitizeForLogs(Object? value) {
    return AppLogger.sanitize(value);
  }
}
