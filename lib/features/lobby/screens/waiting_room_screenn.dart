import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spellit/core/network_utils.dart';
import '../../../models/room_model.dart';
import '../room_service.dart';
import 'package:spellit/features/auth/auth_service.dart';

// Test-overridable user lookup. Defaults to Firestore-backed lookup but tests
// can replace this with a fast in-memory function to avoid initializing
// Firebase during widget tests.
Future<Map<String, dynamic>?> Function(String playerId) userLookup =
    (playerId) async {
  final snap = await AppNetwork.execute<DocumentSnapshot>(
    operationName: 'waitingRoomUserLookup',
    action: () =>
        FirebaseFirestore.instance.collection('users').doc(playerId).get(),
  );
  if (!snap.exists) return null;
  return snap.data() as Map<String, dynamic>?;
};

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const WaitingRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  bool _hasNavigated = false;

  // Memoize per-player lookups so room snapshot updates don't re-issue a
  // Firestore read for every player on every rebuild (avoids N+1 reads).
  final Map<String, Future<Map<String, dynamic>?>> _playerFutures = {};

  Future<Map<String, dynamic>?> _lookupPlayer(String playerId) =>
      _playerFutures.putIfAbsent(playerId, () => userLookup(playerId));
  @override
  Widget build(BuildContext context) {
    final roomService = ref.watch(roomServiceProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return StreamBuilder<RoomModel?>(
        stream: roomService.getRoomStream(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Waiting Room')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 56,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load this room right now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

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
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
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
              context.pushReplacement('/game/${widget.roomId}');
            });
          }

          final isHost = currentUser?.uid == room.hostId;
          final canStart = room.playerIds.length >= 2;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Waiting Room'),
              leading: BackButton(onPressed: () => _leaveRoom(room, currentUser?.uid)),
            ),
            body: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Room Code
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      room.roomCode,
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 8,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copy room code',
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: room.roomCode),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Room code copied'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Share this code with friends to join',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: -0.2),

                        const SizedBox(height: 12),

                        // Game Settings
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                alignment: WrapAlignment.spaceAround,
                                spacing: 12,
                                runSpacing: 8,
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

                        const SizedBox(height: 12),

                        // Players header
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Players List
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: room.playerIds.map((playerId) {
                              final isPlayerHost = playerId == room.hostId;
                              final isCurrentUser = playerId == currentUser?.uid;

                              return FutureBuilder<Map<String, dynamic>?>(
                                future: _lookupPlayer(playerId),
                                builder: (context, playerSnapshot) {
                                  String playerName = 'Player';
                                  int playerElo = 1000;

                                  if (playerSnapshot.hasData && playerSnapshot.data != null) {
                                    final playerData = playerSnapshot.data!;
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
                                          playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Flexible(child: Text(playerName)),
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
                                              icon: const Icon(Icons.remove_circle_outline),
                                              color: Colors.red,
                                              onPressed: () => _kickPlayer(playerId),
                                            )
                                          : null,
                                    ),
                                  ).animate().fadeIn().slideX();
                                },
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Waiting indicator or Start button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                    Expanded(
                                      child: Text(
                                        'Waiting for host to start...',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                        softWrap: true,
                                      ),
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

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        });
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to start game: $e')));
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
