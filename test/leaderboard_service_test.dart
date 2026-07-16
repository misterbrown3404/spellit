import 'package:flutter_test/flutter_test.dart';
import 'package:spellit/features/leaderboard/leaderboard_service.dart';

void main() {
  group('calculateLeaderboardRank', () {
    test('returns the correct rank for the current user when scores are tied', () {
      final entries = [
        const LeaderboardEntry(userId: 'u1', displayName: 'Alice', value: 3000),
        const LeaderboardEntry(userId: 'u2', displayName: 'Bob', value: 3000),
        const LeaderboardEntry(userId: 'u3', displayName: 'Cara', value: 2500),
      ];

      expect(calculateLeaderboardRank(entries, 'u2'), 1);
      expect(calculateLeaderboardRank(entries, 'u3'), 3);
    });

    test('returns null when the user is not in the ranked list', () {
      final entries = [
        const LeaderboardEntry(userId: 'u1', displayName: 'Alice', value: 3000),
        const LeaderboardEntry(userId: 'u2', displayName: 'Bob', value: 2500),
      ];

      expect(calculateLeaderboardRank(entries, 'u9'), isNull);
    });
  });
}
