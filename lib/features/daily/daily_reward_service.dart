import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/firebase_providers.dart';
import '../../core/network_utils.dart';

final dailyRewardServiceProvider = Provider((ref) {
  return DailyRewardService(firestore: ref.watch(firebaseFirestoreProvider));
});

class DailyRewardDefinition {
  const DailyRewardDefinition({
    required this.day,
    required this.coins,
    required this.icon,
    this.bonus,
  });

  final int day;
  final int coins;
  final IconData icon;
  final String? bonus;
}

class DailyRewardState {
  const DailyRewardState({
    required this.currentStreak,
    required this.todayReward,
    required this.hasClaimedToday,
  });

  final int currentStreak;
  final int todayReward;
  final bool hasClaimedToday;
}

class DailyRewardClaimResult {
  const DailyRewardClaimResult({
    required this.coins,
    required this.currentStreak,
    this.bonus,
  });

  final int coins;
  final int currentStreak;
  final String? bonus;
}

class DailyRewardException implements Exception {
  const DailyRewardException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DailyRewardService {
  DailyRewardService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const rewards = [
    DailyRewardDefinition(
      day: 1,
      coins: 10,
      icon: Icons.monetization_on,
    ),
    DailyRewardDefinition(
      day: 2,
      coins: 15,
      icon: Icons.monetization_on,
    ),
    DailyRewardDefinition(
      day: 3,
      coins: 25,
      icon: Icons.monetization_on,
    ),
    DailyRewardDefinition(
      day: 4,
      coins: 35,
      icon: Icons.monetization_on,
    ),
    DailyRewardDefinition(
      day: 5,
      coins: 50,
      icon: Icons.monetization_on,
    ),
    DailyRewardDefinition(
      day: 6,
      coins: 75,
      icon: Icons.monetization_on,
    ),
    DailyRewardDefinition(
      day: 7,
      coins: 100,
      icon: Icons.card_giftcard,
      bonus: 'shuffle',
    ),
  ];

  Future<DailyRewardState> loadState(String userId) async {
    final doc = await AppNetwork.execute<DocumentSnapshot<Map<String, dynamic>>>(
      operationName: 'loadDailyRewardState',
      action: () => _firestore.collection('users').doc(userId).get(),
    );

    final data = doc.data() ?? {};
    final streak = data['dailyRewardStreak'] as int? ??
        data['currentStreak'] as int? ??
        0;
    final lastClaimedAt =
        (data['dailyRewardClaimedAt'] as Timestamp?)?.toDate();
    final dayIndex = streak % rewards.length;

    return DailyRewardState(
      currentStreak: streak,
      todayReward: rewards[dayIndex].coins,
      hasClaimedToday: _isSameLocalDay(lastClaimedAt, DateTime.now()),
    );
  }

  Future<DailyRewardClaimResult> claim(String userId) {
    final userRef = _firestore.collection('users').doc(userId);

    return AppNetwork.execute<DailyRewardClaimResult>(
      operationName: 'claimDailyReward',
      action: () => _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw const DailyRewardException('Player profile not found.');
        }

        final data = snapshot.data() ?? {};
        final lastClaimedAt =
            (data['dailyRewardClaimedAt'] as Timestamp?)?.toDate();
        if (_isSameLocalDay(lastClaimedAt, DateTime.now())) {
          throw const DailyRewardException(
            'Daily reward has already been claimed today.',
          );
        }

        final currentStreak = data['dailyRewardStreak'] as int? ??
            data['currentStreak'] as int? ??
            0;
        final reward = rewards[currentStreak % rewards.length];
        final nextStreak = currentStreak + 1;

        final updateData = <String, dynamic>{
          'dailyRewardClaimedAt': FieldValue.serverTimestamp(),
          'dailyRewardStreak': nextStreak,
          'coins': FieldValue.increment(reward.coins),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (reward.bonus != null) {
          updateData['inventory.${reward.bonus}'] = FieldValue.increment(1);
        }

        transaction.update(userRef, updateData);

        return DailyRewardClaimResult(
          coins: reward.coins,
          currentStreak: nextStreak,
          bonus: reward.bonus,
        );
      }),
    );
  }

  static bool _isSameLocalDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
