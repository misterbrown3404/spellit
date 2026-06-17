import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spellit/models/achievement_model.dart';

void main() {
  testWidgets('AchievementModel predefined list is valid', (WidgetTester tester) async {
    final achievements = AchievementModel.predefinedAchievements();
    expect(achievements, isNotEmpty);
    expect(achievements.first.title, isNotEmpty);
    expect(achievements.first.id, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text(achievements.first.title),
        ),
      ),
    );

    expect(find.text(achievements.first.title), findsOneWidget);
  });
}
