import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String odid;
  final String displayName;
  final String email;
  final String avatarUrl;
  final int coins;
  final int gems;
  final int eloRating;
  final int totalGamesPlayed;
  final int totalWins;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastLoginDate;
  final Map<String, int> inventory; // { 'freeze': 2, 'reveal': 1, 'shuffle': 3 }
  final Map<String, int> achievementProgress;
  final List<String> unlockedAchievements;
  final int totalWordsFound;
  final int highestSingleGameScore;

  PlayerModel({
    required this.odid,
    required this.displayName,
    required this.email,
    this.avatarUrl = '',
    this.coins = 100,
    this.gems = 0,
    this.eloRating = 1000,
    this.totalGamesPlayed = 0,
    this.totalWins = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastLoginDate,
    this.inventory = const {'freeze': 0, 'reveal': 0, 'shuffle': 1},
    this.achievementProgress = const {},
    this.unlockedAchievements = const [],
    this.totalWordsFound = 0,
    this.highestSingleGameScore = 0,
  });

  factory PlayerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerModel(
      odid: doc.id,
      displayName: data['displayName'] ?? 'Player',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      coins: data['coins'] ?? 100,
      gems: data['gems'] ?? 0,
      eloRating: data['eloRating'] ?? 1000,
      totalGamesPlayed: data['totalGamesPlayed'] ?? 0,
      totalWins: data['totalWins'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastLoginDate: (data['lastLoginDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inventory: Map<String, int>.from(data['inventory'] ?? {}),
      achievementProgress: Map<String, int>.from(data['achievementProgress'] ?? {}),
      unlockedAchievements: List<String>.from(data['unlockedAchievements'] ?? []),
      totalWordsFound: data['totalWordsFound'] ?? 0,
      highestSingleGameScore: data['highestSingleGameScore'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'coins': coins,
      'gems': gems,
      'eloRating': eloRating,
      'totalGamesPlayed': totalGamesPlayed,
      'totalWins': totalWins,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastLoginDate': Timestamp.fromDate(lastLoginDate),
      'inventory': inventory,
      'achievementProgress': achievementProgress,
      'unlockedAchievements': unlockedAchievements,
      'totalWordsFound': totalWordsFound,
      'highestSingleGameScore': highestSingleGameScore,
    };
  }

  PlayerModel copyWith({
    String? displayName,
    int? coins,
    int? gems,
    int? eloRating,
    int? totalGamesPlayed,
    int? totalWins,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    Map<String, int>? inventory,
    Map<String, int>? achievementProgress,
    List<String>? unlockedAchievements,
    int? totalWordsFound,
    int? highestSingleGameScore,
  }) {
    return PlayerModel(
      odid: odid,
      displayName: displayName ?? this.displayName,
      email: email,
      avatarUrl: avatarUrl,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      eloRating: eloRating ?? this.eloRating,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      inventory: inventory ?? this.inventory,
      achievementProgress: achievementProgress ?? this.achievementProgress,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      totalWordsFound: totalWordsFound ?? this.totalWordsFound,
      highestSingleGameScore: highestSingleGameScore ?? this.highestSingleGameScore,
    );
  }
}