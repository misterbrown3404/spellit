import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int targetCount;
  final String category;
  final int rewardCoins;
  final int rewardGems;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetCount,
    required this.category,
    this.rewardCoins = 0,
    this.rewardGems = 0,
  });

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AchievementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'star',
      targetCount: data['targetCount'] ?? 1,
      category: data['category'] ?? 'general',
      rewardCoins: data['rewardCoins'] ?? 0,
      rewardGems: data['rewardGems'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'targetCount': targetCount,
      'category': category,
      'rewardCoins': rewardCoins,
      'rewardGems': rewardGems,
    };
  }

  static List<AchievementModel> predefinedAchievements() => const [
        AchievementModel(
          id: 'first_win',
          title: 'First Blood',
          description: 'Win your first game',
          icon: 'emoji_events',
          targetCount: 1,
          category: 'games',
          rewardCoins: 50,
        ),
        AchievementModel(
          id: 'win_10',
          title: 'Victorious',
          description: 'Win 10 multiplayer games',
          icon: 'emoji_events',
          targetCount: 10,
          category: 'games',
          rewardCoins: 200,
          rewardGems: 5,
        ),
        AchievementModel(
          id: 'games_50',
          title: 'Veteran',
          description: 'Play 50 total games',
          icon: 'military_tech',
          targetCount: 50,
          category: 'games',
          rewardCoins: 300,
          rewardGems: 10,
        ),
        AchievementModel(
          id: 'words_100',
          title: 'Word Smith',
          description: 'Discover 100 words',
          icon: 'menu_book',
          targetCount: 100,
          category: 'words',
          rewardCoins: 150,
        ),
        AchievementModel(
          id: 'streak_7',
          title: 'Week Warrior',
          description: 'Maintain a 7-day login streak',
          icon: 'local_fire_department',
          targetCount: 7,
          category: 'streak',
          rewardCoins: 100,
          rewardGems: 3,
        ),
        AchievementModel(
          id: 'streak_30',
          title: 'Unstoppable',
          description: 'Maintain a 30-day login streak',
          icon: 'whatshot',
          targetCount: 30,
          category: 'streak',
          rewardCoins: 500,
          rewardGems: 20,
        ),
      ];
}
