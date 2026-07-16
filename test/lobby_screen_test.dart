import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spellit/features/lobby/room_service.dart';
import 'package:spellit/features/lobby/screens/lobby_screen.dart';
import 'package:spellit/models/room_model.dart';

class _FakeRoomService implements RoomService {
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
  Future<void> startNewRound(String roomId) async {
    // no-op for tests
    return;
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
  Stream<RoomModel?> getRoomStream(String roomId) {
    throw UnimplementedError();
  }

  @override
  Stream<List<RoomModel>> getPublicRooms() => Stream.value([]);

  @override
  Future<void> endGame(String roomId) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('LobbyScreen renders correctly on a small viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [roomServiceProvider.overrideWithValue(_FakeRoomService())],
        child: const MaterialApp(home: LobbyScreen()),
      ),
    );

    expect(find.text('Create Room'), findsWidgets);
    expect(find.text('Join Room'), findsWidgets);

    await tester.tap(find.text('Join Room'));
    await tester.pumpAndSettle();

    expect(find.text('Enter Room Code'), findsOneWidget);
    expect(find.text('No public rooms available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
