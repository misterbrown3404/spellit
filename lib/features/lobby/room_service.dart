import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/firebase_providers.dart';
import '../../core/network_utils.dart';
import '../../models/room_model.dart';

final roomServiceProvider = Provider((ref) {
  return RoomService(firestore: ref.watch(firebaseFirestoreProvider));
});

class RoomService {
  RoomService({required FirebaseFirestore firestore})
      : _firestore = firestore,
        _roomsRef = firestore.collection('rooms');

  final FirebaseFirestore _firestore;
  final CollectionReference _roomsRef;

  // Generate unique room code — 8 chars gives ~2.8 trillion combos,
  // making collisions astronomically rare without a server round-trip.
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // Generate balanced letter grid (vowels + consonants)
  List<String> _generateBalancedGrid(int size) {
    const vowels = 'AEIOU';
    const consonants = 'BCDFGHJKLMNPQRSTVWXYZ';
    Random rnd = Random();

    int totalCells = size * size;
    int vowelCount = (totalCells * 0.35).round(); // ~35% vowels for playability

    List<String> grid = [];

    // Add vowels
    for (int i = 0; i < vowelCount; i++) {
      grid.add(vowels[rnd.nextInt(vowels.length)]);
    }

    // Add consonants
    for (int i = vowelCount; i < totalCells; i++) {
      grid.add(consonants[rnd.nextInt(consonants.length)]);
    }

    // Shuffle the grid
    grid.shuffle(rnd);

    return grid;
  }

  // Create a new room — optimistic single write, no uniqueness pre-check needed
  Future<RoomModel> createRoom({
    required String hostId,
    int maxPlayers = 4,
    int wordLengthMin = 3,
    int wordLengthMax = 7,
    int timeLimit = 120,
    int totalRounds = 3,
    GameMode gameMode = GameMode.classic,
    bool isPublic = true,
  }) async {
    final roomCode = _generateRoomCode();
    final roomId = _roomsRef.doc().id;
    final gridLetters = _generateBalancedGrid(7);

    final room = RoomModel(
      roomId: roomId,
      roomCode: roomCode,
      hostId: hostId,
      playerIds: [hostId],
      scores: {hostId: 0},
      wordsFound: {hostId: []},
      status: RoomStatus.waiting,
      gameMode: gameMode,
      maxPlayers: maxPlayers,
      wordLengthMin: wordLengthMin,
      wordLengthMax: wordLengthMax,
      timeLimit: timeLimit,
      totalRounds: totalRounds,
      gridLetters: gridLetters,
      createdAt: DateTime.now(),
      isPublic: isPublic,
    );

    await AppNetwork.execute<void>(
      operationName: 'createRoom',
      action: () => _roomsRef.doc(roomId).set(room.toFirestore()),
    );

    return room;
  }

  // Join room by code
  Future<RoomModel?> joinRoom({
    required String roomCode,
    required String playerId,
  }) async {
    final normalized = roomCode.trim().toUpperCase();
    final query = await AppNetwork.execute<QuerySnapshot>(
      operationName: 'findRoomByCode',
      action: () => _roomsRef
          .where('roomCode', isEqualTo: normalized)
          .limit(1)
          .get(),
    );

    if (query.docs.isEmpty) {
      throw Exception('Room not found');
    }

    final roomDoc = query.docs.first;
    return AppNetwork.execute<RoomModel>(
      operationName: 'joinRoom',
      action: () => _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomDoc.reference);
        if (!snapshot.exists) {
          throw Exception('Room not found');
        }

        final room = RoomModel.fromFirestore(snapshot);

        if (room.status != RoomStatus.waiting) {
          throw Exception('Game already started');
        }

        if (room.playerIds.contains(playerId)) {
          return room;
        }

        if (room.playerIds.length >= room.maxPlayers) {
          throw Exception('Room is full');
        }

        transaction.update(roomDoc.reference, {
          'playerIds': FieldValue.arrayUnion([playerId]),
          'scores.$playerId': 0,
          'wordsFound.$playerId': <String>[],
        });

        return RoomModel(
          roomId: room.roomId,
          roomCode: room.roomCode,
          hostId: room.hostId,
          playerIds: [...room.playerIds, playerId],
          scores: {...room.scores, playerId: 0},
          wordsFound: {...room.wordsFound, playerId: <String>[]},
          status: room.status,
          gameMode: room.gameMode,
          maxPlayers: room.maxPlayers,
          wordLengthMin: room.wordLengthMin,
          wordLengthMax: room.wordLengthMax,
          timeLimit: room.timeLimit,
          currentRound: room.currentRound,
          totalRounds: room.totalRounds,
          gridLetters: room.gridLetters,
          createdAt: room.createdAt,
          gameStartedAt: room.gameStartedAt,
          activeEffects: room.activeEffects,
          isPublic: room.isPublic,
        );
      }),
    );
  }

  // Leave room
  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  }) async {
    final roomDoc = _roomsRef.doc(roomId);
    final snapshot = await AppNetwork.execute<DocumentSnapshot>(
      operationName: 'loadRoomForLeave',
      action: () => roomDoc.get(),
    );

    if (!snapshot.exists) return;

    final room = RoomModel.fromFirestore(snapshot);

    if (room.hostId == playerId) {
      // Host leaving - delete room or transfer ownership
      if (room.playerIds.length <= 1) {
        await AppNetwork.execute<void>(
          operationName: 'deleteEmptyRoom',
          action: () => roomDoc.delete(),
        );
      } else {
        final newHost = room.playerIds.firstWhere((id) => id != playerId);
        await AppNetwork.execute<void>(
          operationName: 'transferRoomHost',
          action: () => roomDoc.update({
            'hostId': newHost,
            'playerIds': FieldValue.arrayRemove([playerId]),
          }),
        );
      }
    } else {
      await AppNetwork.execute<void>(
        operationName: 'leaveRoom',
        action: () => roomDoc.update({
          'playerIds': FieldValue.arrayRemove([playerId]),
        }),
      );
    }
  }

  // Start the game
  Future<void> startGame(String roomId) async {
    await AppNetwork.execute<void>(
      operationName: 'startGame',
      action: () => _roomsRef.doc(roomId).update({
        'status': 'playing',
        'gameStartedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  // Submit word and update score
  Future<bool> submitWord({
    required String roomId,
    required String playerId,
    required String word,
    required int score,
  }) async {
    final roomDoc = _roomsRef.doc(roomId);

    return AppNetwork.execute<bool>(
      operationName: 'submitWord',
      action: () => _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomDoc);
        final room = RoomModel.fromFirestore(snapshot);

        for (var words in room.wordsFound.values) {
          if (words.contains(word.toUpperCase())) {
            return false;
          }
        }

        transaction.update(roomDoc, {
          'scores.$playerId': FieldValue.increment(score),
          'wordsFound.$playerId': FieldValue.arrayUnion([word.toUpperCase()]),
        });

        return true;
      }),
    );
  }

  // Use power-up
  Future<void> usePowerUp({
    required String roomId,
    required String odidUser,
    required String targetPlayerId,
    required String powerUpType,
    required int duration,
  }) async {
    final endTime = DateTime.now().add(Duration(seconds: duration));

    await AppNetwork.execute<void>(
      operationName: 'usePowerUp',
      action: () => _roomsRef.doc(roomId).update({
        'activeEffects.$targetPlayerId': {
          'type': powerUpType,
          'fromPlayer': odidUser,
          'endTime': Timestamp.fromDate(endTime),
        },
      }),
    );
  }

  // Get room stream
  Stream<RoomModel?> getRoomStream(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RoomModel.fromFirestore(doc);
    });
  }

  // Get available public rooms
  Stream<List<RoomModel>> getPublicRooms() {
    return _roomsRef
        .where('status', isEqualTo: 'waiting')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> endGame(String roomId) async {
    final roomDoc = _roomsRef.doc(roomId);
    final snapshot = await roomDoc.get();

    if (!snapshot.exists) return;

    final room = RoomModel.fromFirestore(snapshot);

    // Determine winner
    String? winnerId;
    int highestScore = 0;

    for (var entry in room.scores.entries) {
      if (entry.value > highestScore) {
        highestScore = entry.value;
        winnerId = entry.key;
      }
    }

    await roomDoc.update({
      'status': 'finished',
      'winnerId': winnerId, // ← now used
      'highestScore': highestScore, // ← now used
      'finishedAt': FieldValue.serverTimestamp(),
    });
  }

  // New round with fresh grid
  Future<void> startNewRound(String roomId) async {
    final newGrid = _generateBalancedGrid(7);

    await _roomsRef.doc(roomId).update({
      'gridLetters': newGrid,
      'currentRound': FieldValue.increment(1),
      'wordsFound': {}, // Reset words found for new round
      'activeEffects': {}, // Clear active effects
    });
  }
}
