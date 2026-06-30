import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spellit/features/chat/screens/chat_screen.dart';
import 'package:spellit/features/auth/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spellit/features/game/screens/multiplayer_game_screen.dart';
import '../../../models/room_model.dart';

import '../room_service.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const WaitingRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final roomService = ref.watch(roomServiceProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return StreamBuilder<RoomModel?>(
      stream: roomService.getRoomStream(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final room = snapshot.data;
        if (room == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Room not found or was deleted'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Navigate to game when status changes to playing
        if (room.status == RoomStatus.playing && !_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MultiplayerGameScreen(roomId: widget.roomId),
              ),
            );
          });
        }

        final isHost = currentUser?.uid == room.hostId;
        final canStart = room.playerIds.length >= 2;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Waiting Room'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _leaveRoom(room, currentUser?.uid),
            ),
          ),
          body: Column(
            children: [
              // Room Code Display
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Room Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room.roomCode,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: room.roomCode),
                            );
                            final inviteText = room.isPublic
                                ? 'Join my public SpellIt game! Room code: ${room.roomCode}'
                                : 'Join my private SpellIt game! Room code: ${room.roomCode}';
                            final initialTab = room.isPublic ? 0 : 1;
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    initialMessage: inviteText,
                                    initialTab: initialTab,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share this code with friends to join',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              // Game Settings Display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSettingItem(
                          icon: Icons.timer,
                          label: 'Time',
                          value: '${room.timeLimit}s',
                        ),
                        _buildSettingItem(
                          icon: Icons.text_fields,
                          label: 'Min Length',
                          value: '${room.wordLengthMin}',
                        ),
                        _buildSettingItem(
                          icon: Icons.repeat,
                          label: 'Rounds',
                          value: '${room.totalRounds}',
                        ),
                        _buildSettingItem(
                          icon: Icons.sports_esports,
                          label: 'Mode',
                          value: room.gameMode.name,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // Players List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Players',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${room.playerIds.length}/${room.maxPlayers}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: room.playerIds.length,
                  itemBuilder: (context, index) {
                    final playerId = room.playerIds[index];
                    final isPlayerHost = playerId == room.hostId;
                    final isCurrentUser = playerId == currentUser?.uid;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(playerId)
                          .get(),
                      builder: (context, playerSnapshot) {
                        String playerName = 'Loading...';
                        int playerElo = 1000;

                        if (playerSnapshot.hasData &&
                            playerSnapshot.data!.exists) {
                          final playerData =
                              playerSnapshot.data!.data()
                                  as Map<String, dynamic>;
                          playerName = playerData['displayName'] ?? 'Player';
                          playerElo = playerData['eloRating'] ?? 1000;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isCurrentUser
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPlayerHost
                                  ? Colors.amber
                                  : Theme.of(context).colorScheme.primary,
                              child: Text(
                                playerName.isNotEmpty
                                    ? playerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(playerName),
                                if (isPlayerHost) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'HOST',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 8),
                                  const Text(
                                    '(You)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text('ELO: $playerElo'),
                            trailing: isHost && !isPlayerHost
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    color: Colors.red,
                                    onPressed: () => _kickPlayer(playerId),
                                  )
                                : null,
                          ),
                        ).animate().fadeIn(delay: (100 * index).ms).slideX();
                      },
                    );
                  },
                ),
              ),

              // Waiting indicator or Start button
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (!isHost)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Waiting for host to start...',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          if (!canStart)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Need at least 2 players to start',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: canStart ? _startGame : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Game'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _startGame() async {
    try {
      await ref.read(roomServiceProvider).startGame(widget.roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start game: $e')));
      }
    }
  }

  Future<void> _leaveRoom(RoomModel room, String? odid) async {
    if (odid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room?'),
        content: Text(
          room.hostId == odid
              ? 'You are the host. Leaving will close the room for everyone.'
              : 'Are you sure you want to leave this room?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(roomServiceProvider)
          .leaveRoom(roomId: widget.roomId, playerId: odid);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _kickPlayer(String playerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick Player?'),
        content: const Text('Are you sure you want to remove this player?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kick'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(roomServiceProvider)
          .leaveRoom(roomId: widget.roomId, playerId: playerId);
    }
  }
}
