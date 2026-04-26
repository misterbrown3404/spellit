import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { waiting, playing, finished }
enum GameMode { classic, blitz, marathon }

class RoomModel {
  final String roomId;
  final String roomCode; // 6-digit code for joining
  final String hostId;
  final List<String> playerIds;
  final Map<String, int> scores; // { 'uid1': 50, 'uid2': 30 }
  final Map<String, List<String>> wordsFound; // Track words each player found
  final RoomStatus status;
  final GameMode gameMode;
  final int maxPlayers;
  final int wordLengthMin;
  final int wordLengthMax;
  final int timeLimit; // in seconds
  final int currentRound;
  final int totalRounds;
  final List<String> gridLetters;
  final DateTime createdAt;
  final DateTime? gameStartedAt;
  final Map<String, dynamic> activeEffects; // Power-up effects

  RoomModel({
    required this.roomId,
    required this.roomCode,
    required this.hostId,
    required this.playerIds,
    this.scores = const {},
    this.wordsFound = const {},
    this.status = RoomStatus.waiting,
    this.gameMode = GameMode.classic,
    this.maxPlayers = 4,
    this.wordLengthMin = 3,
    this.wordLengthMax = 7,
    this.timeLimit = 120,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.gridLetters = const [],
    required this.createdAt,
    this.gameStartedAt,
    this.activeEffects = const {},
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      roomId: doc.id,
      roomCode: data['roomCode'] ?? '',
      hostId: data['hostId'] ?? '',
      playerIds: List<String>.from(data['playerIds'] ?? []),
      scores: Map<String, int>.from(data['scores'] ?? {}),
      wordsFound: (data['wordsFound'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ?? {},
      status: RoomStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RoomStatus.waiting,
      ),
      gameMode: GameMode.values.firstWhere(
        (e) => e.name == data['gameMode'],
        orElse: () => GameMode.classic,
      ),
      maxPlayers: data['maxPlayers'] ?? 4,
      wordLengthMin: data['wordLengthMin'] ?? 3,
      wordLengthMax: data['wordLengthMax'] ?? 7,
      timeLimit: data['timeLimit'] ?? 120,
      currentRound: data['currentRound'] ?? 1,
      totalRounds: data['totalRounds'] ?? 3,
      gridLetters: List<String>.from(data['gridLetters'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gameStartedAt: (data['gameStartedAt'] as Timestamp?)?.toDate(),
      activeEffects: Map<String, dynamic>.from(data['activeEffects'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'playerIds': playerIds,
      'scores': scores,
      'wordsFound': wordsFound,
      'status': status.name,
      'gameMode': gameMode.name,
      'maxPlayers': maxPlayers,
      'wordLengthMin': wordLengthMin,
      'wordLengthMax': wordLengthMax,
      'timeLimit': timeLimit,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'gridLetters': gridLetters,
      'createdAt': Timestamp.fromDate(createdAt),
      'gameStartedAt': gameStartedAt != null ? Timestamp.fromDate(gameStartedAt!) : null,
      'activeEffects': activeEffects,
    };
  }
}