import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spellit/core/errors/app_error.dart';
import 'package:spellit/core/errors/error_classifier.dart';

void main() {
  group('ErrorClassifier', () {
    test('classifies timeouts as retryable network errors', () {
      final error = ErrorClassifier.classify(
        TimeoutException('slow request'),
      );

      expect(error.category, AppErrorCategory.network);
      expect(error.isRetryable, isTrue);
      expect(error.userMessage, contains('try again'));
    });

    test('maps Firebase auth errors to safe user messages', () {
      final error = ErrorClassifier.classify(
        FirebaseAuthException(code: 'wrong-password'),
      );

      expect(error.category, AppErrorCategory.authentication);
      expect(error.userMessage, 'The email or password is incorrect.');
      expect(error.developerMessage, contains('wrong-password'));
    });

    test('marks transient Firebase failures retryable', () {
      final error = ErrorClassifier.classify(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      expect(error.category, AppErrorCategory.firebase);
      expect(error.isRetryable, isTrue);
      expect(error.userMessage, contains('Network error'));
    });
  });
}
