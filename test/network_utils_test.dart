import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:spellit/core/network_utils.dart';

void main() {
  group('sanitizeForLogs', () {
    test('redacts long values while preserving structure', () {
      expect(AppNetwork.sanitizeForLogs('super-secret-token'), contains('***'));
      expect(AppNetwork.sanitizeForLogs('abc123'), 'abc123');
    });
  });

  group('AppNetwork.execute', () {
    test('retries until a successful result is produced', () async {
      var attempts = 0;

      final result = await AppNetwork.execute<int>(
        action: () async {
          attempts++;
          if (attempts < 3) {
            throw TimeoutException('slow', const Duration(seconds: 1));
          }
          return 42;
        },
        timeout: const Duration(seconds: 1),
        maxAttempts: 3,
        retryDelay: Duration.zero,
      );

      expect(result, 42);
      expect(attempts, 3);
    });
  });
}
