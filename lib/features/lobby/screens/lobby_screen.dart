import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../models/room_model.dart';
import '../../auth/auth_service.dart';
import '../room_service.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _roomCodeController = TextEditingController();
  bool _isLoading = false;

  // Game settings
  int _wordLengthMin = 3;
  int _timeLimit = 120;
  int _maxPlayers = 4;
  int _totalRounds = 3;
  GameMode _gameMode = GameMode.classic;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final roomService = ref.read(roomServiceProvider);
      final room = await roomService.createRoom(
        hostId: user.uid,
        maxPlayers: _maxPlayers,
        wordLengthMin: _wordLengthMin,
        timeLimit: _timeLimit,
        totalRounds: _totalRounds,
        gameMode: _gameMode,
        isPublic: _isPublic,
      );

      if (mounted) {
        context.push('/waiting/${room.roomId}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.length != 6) {
      _showError('Enter a valid 6-character room code');
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final roomService = ref.read(roomServiceProvider);
      final room = await roomService.joinRoom(
        roomCode: code,
        playerId: user.uid,
      );

      if (room != null && mounted) {
        context.push('/waiting/${room.roomId}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create Room'),
            Tab(text: 'Join Room'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCreateRoomTab(),
            _buildJoinRoomTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRoomTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: GameMode.values.map((mode) {
                    return ChoiceChip(
                      label: Text(mode.name.toUpperCase()),
                      selected: _gameMode == mode,
                      onSelected: (selected) {
                        if (selected) setState(() => _gameMode = mode);
                      },
                    );
                  }).toList(),
                ).animate().fadeIn().slideX(begin: -0.1),

                const SizedBox(height: 20),

                Text(
                  'Time Limit: $_timeLimit seconds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _timeLimit.toDouble(),
                  min: 60,
                  max: 300,
                  divisions: 8,
                  label: '${_timeLimit}s',
                  onChanged: (value) {
                    setState(() => _timeLimit = value.round());
                  },
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

                const SizedBox(height: 8),

                Text(
                  'Minimum Word Length: $_wordLengthMin letters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _wordLengthMin.toDouble(),
                  min: 3,
                  max: 6,
                  divisions: 3,
                  label: '$_wordLengthMin',
                  onChanged: (value) {
                    setState(() => _wordLengthMin = value.round());
                  },
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                const SizedBox(height: 8),

                Text(
                  'Max Players: $_maxPlayers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _maxPlayers.toDouble(),
                  min: 2,
                  max: 8,
                  divisions: 6,
                  label: '$_maxPlayers',
                  onChanged: (value) {
                    setState(() => _maxPlayers = value.round());
                  },
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                const SizedBox(height: 8),

                Text(
                  'Total Rounds: $_totalRounds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _totalRounds.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_totalRounds',
                  onChanged: (value) {
                    setState(() => _totalRounds = value.round());
                  },
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                const SizedBox(height: 8),

                SwitchListTile(
                  title: Text(
                    'Public Room',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Allow anyone to join from the lobby'),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() => _isPublic = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.1),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _createRoom,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Create Room'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).scale(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoinRoomTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Icon(
                  Icons.meeting_room_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.5,
                  ),
                ).animate().scale(),

                const SizedBox(height: 20),

                Text(
                  'Enter Room Code',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Ask the host for their 6-character code',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: _roomCodeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '_ _ _ _ _ _',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    UpperCaseTextFormatter(),
                  ],
                ).animate().fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _joinRoom,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Join Room'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Or join a public room',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: _buildPublicRoomsList()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublicRoomsList() {
    final roomService = ref.watch(roomServiceProvider);

    return StreamBuilder<List<RoomModel>>(
      stream: roomService.getPublicRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No public rooms available',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rooms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(child: Text('${room.playerIds.length}')),
                title: Text('Room ${room.roomCode}'),
                subtitle: Text(
                  '${room.playerIds.length}/${room.maxPlayers} players • ${room.timeLimit}s',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    _roomCodeController.text = room.roomCode;
                    _joinRoom();
                  },
                  child: const Text('Join'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Text formatter for uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
