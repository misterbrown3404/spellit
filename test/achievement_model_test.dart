import 'package:flutter_test/flutter_test.dart';
import 'package:spellit/models/achievement_model.dart';

void main() {
  group('AchievementModel', () {
    test('predefinedAchievements returns non-empty list', () {
      final list = AchievementModel.predefinedAchievements();
      expect(list.length, greaterThan(0));
    });

    test('each achievement has required fields', () {
      for (final a in AchievementModel.predefinedAchievements()) {
        expect(a.id, isNotEmpty);
        expect(a.title, isNotEmpty);
        expect(a.icon, isNotEmpty);
        expect(a.targetCount, greaterThan(0));
      }
    });

    test('reward coins and gems are non-negative', () {
      for (final a in AchievementModel.predefinedAchievements()) {
        expect(a.rewardCoins, greaterThanOrEqualTo(0));
        expect(a.rewardGems, greaterThanOrEqualTo(0));
      }
    });
  });
}
