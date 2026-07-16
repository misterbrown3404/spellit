import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../network/network_exceptions.dart';
import 'app_error.dart';

class ErrorClassifier {
  const ErrorClassifier._();

  static AppError classify(Object error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    if (error is TimeoutException || isSocketLikeException(error)) {
      return AppError(
        category: AppErrorCategory.network,
        userMessage:
            'Your connection is taking longer than expected. Please try again.',
        developerMessage: error.toString(),
        cause: error,
        stackTrace: stackTrace,
        isRetryable: true,
      );
    }

    if (error is FirebaseAuthException) {
      return AppError(
        category: AppErrorCategory.authentication,
        userMessage: _authMessage(error.code),
        developerMessage: '${error.code}: ${error.message ?? 'Auth failure'}',
        code: error.code,
        cause: error,
        stackTrace: stackTrace,
        isRetryable: error.code == 'network-request-failed',
      );
    }

    if (error is FirebaseException) {
      return AppError(
        category: AppErrorCategory.firebase,
        userMessage: _firebaseMessage(error.code),
        developerMessage:
            '${error.plugin}/${error.code}: ${error.message ?? 'Firebase failure'}',
        code: error.code,
        cause: error,
        stackTrace: stackTrace,
        isRetryable: _retryableFirebaseCodes.contains(error.code),
      );
    }

    if (error is PlatformException) {
      return AppError(
        category: AppErrorCategory.platform,
        userMessage: 'Something went wrong on this device. Please try again.',
        developerMessage:
            '${error.code}: ${error.message ?? error.details ?? 'Platform failure'}',
        code: error.code,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return AppError(
        category: AppErrorCategory.parsing,
        userMessage: 'We could not read some app data. Please try again.',
        developerMessage: error.toString(),
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return AppError(
      category: AppErrorCategory.unknown,
      userMessage: 'Something went wrong. Please try again.',
      developerMessage: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static const _retryableFirebaseCodes = {
    'aborted',
    'deadline-exceeded',
    'network-request-failed',
    'resource-exhausted',
    'unavailable',
    'unknown',
  };

  static String _authMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'requires-recent-login':
        return 'Please sign in again before completing this action.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  static String _firebaseMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'not-found':
        return 'That item could not be found.';
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'resource-exhausted':
        return 'The service is busy right now. Please try again shortly.';
      default:
        return 'The service could not complete that request. Please try again.';
    }
  }
}
