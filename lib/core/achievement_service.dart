import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement_model.dart';
import '../../models/player_model.dart';

final achievementServiceProvider = Provider((ref) => AchievementService());

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AchievementModel>> getUnlockedAchievements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AchievementModel.fromFirestore(doc))
            .toList());
  }

  Future<void> unlockAchievement(String userId, AchievementModel achievement) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .set({
        ...achievement.toFirestore(),
        'unlockedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userId).update({
        'coins': FieldValue.increment(achievement.rewardCoins),
        'gems': FieldValue.increment(achievement.rewardGems),
      });
    } catch (e) {
      throw Exception('Failed to unlock achievement');
    }
  }

  Future<void> checkAndGrantAchievements(String userId, PlayerModel player) async {
    final achievements = AchievementModel.predefinedAchievements();
    for (final achievement in achievements) {
      int currentProgress = 0;
      switch (achievement.id) {
        case 'first_win':
        case 'win_10':
          currentProgress = player.totalWins;
          break;
        case 'games_50':
          currentProgress = player.totalGamesPlayed;
          break;
        case 'streak_7':
          currentProgress = player.currentStreak;
          break;
        case 'streak_30':
          currentProgress = player.longestStreak;
          break;
        default:
          continue;
      }

      if (currentProgress >= achievement.targetCount) {
        final alreadyUnlocked = await _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievement.id)
            .get();

        if (!alreadyUnlocked.exists) {
          await unlockAchievement(userId, achievement);
        }
      }
    }
  }
}
