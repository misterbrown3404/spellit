import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spellit/features/auth/auth_service.dart';
import 'package:spellit/features/lobby/room_service.dart';
import 'package:spellit/features/lobby/screens/waiting_room_screenn.dart';
import 'package:spellit/models/room_model.dart';

class _FakeRoomService implements RoomService {
  @override
  Stream<RoomModel?> getRoomStream(String roomId) =>
      Stream.value(RoomModel(
        roomId: 'r1',
        roomCode: 'ABC123',
        hostId: 'host1',
        playerIds: ['host1'],
        scores: {'host1': 0},
        wordsFound: {'host1': []},
        status: RoomStatus.waiting,
        gameMode: GameMode.classic,
        maxPlayers: 4,
        wordLengthMin: 3,
        wordLengthMax: 7,
        timeLimit: 120,
        totalRounds: 3,
        gridLetters: List.generate(49, (i) => 'A'),
        createdAt: DateTime.now(),
        isPublic: true,
      ));

  // Remaining methods are no-ops or unimplemented for this fake
  @override
  Future<RoomModel> createRoom({
    required String hostId,
    int maxPlayers = 4,
    int wordLengthMin = 3,
    int wordLengthMax = 7,
    int timeLimit = 120,
    int totalRounds = 3,
    GameMode gameMode = GameMode.classic,
    bool isPublic = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RoomModel?> joinRoom({required String roomCode, required String playerId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveRoom({required String roomId, required String playerId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> startGame(String roomId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> submitWord({required String roomId, required String playerId, required String word, required int score}) {
    throw UnimplementedError();
  }

  @override
  Future<void> usePowerUp({required String roomId, required String odidUser, required String targetPlayerId, required String powerUpType, required int duration}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<RoomModel>> getPublicRooms() => Stream.value([]);

  @override
  Future<void> endGame(String roomId) {
    throw UnimplementedError();
  }

  @override
  Future<void> startNewRound(String roomId) async {
    return;
  }
}

void main() {
  testWidgets('WaitingRoomScreen renders with room info', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Override userLookup so test doesn't call Firestore
    userLookup = (id) async => {'displayName': 'Test', 'eloRating': 1200};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomServiceProvider.overrideWithValue(_FakeRoomService()),
          // Prevent FirebaseAuth from being accessed in tests
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: WaitingRoomScreen(roomId: 'r1'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify core pieces of UI render
    expect(find.text('Players'), findsOneWidget);
  });
}
