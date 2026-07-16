import 'dart:async';
import 'package:spellit/core/notification_service.dart';
import 'package:spellit/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:spellit/core/setting_service.dart';
import '../../../core/audio_manager.dart';
import '../../../core/dictionary_service.dart';
import '../../../models/room_model.dart';
import '../../../models/power_up_model.dart';
import '../../auth/auth_service.dart';
import '../../leaderboard/leaderboard_service.dart';
import '../../lobby/room_service.dart';
import '../widgets/letter_grid.dart';
import '../widgets/game_timer.dart';
import '../widgets/power_up_bar.dart';
import '../widgets/score_display.dart';
import '../widgets/word_display.dart';

class MultiplayerGameScreen extends ConsumerStatefulWidget {
  final String roomId;

  const MultiplayerGameScreen({super.key, required this.roomId});

  @override
  ConsumerState<MultiplayerGameScreen> createState() =>
      _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends ConsumerState<MultiplayerGameScreen>
    with TickerProviderStateMixin {
  final int gridSize = 7;
  List<int> selectedIndices = [];
  String currentWord = "";
  bool isWordValid = false;
  int? potentialScore;

  // Power-up states
  bool isFrozen = false;
  int frozenSecondsRemaining = 0;
  Timer? frozenTimer;
  bool isDoublePoints = false;
  Timer? doublePointsTimer;
  List<int> disabledIndices = [];
  Timer? bombTimer;
  bool hasShield = false;

  // Player inventory (loaded from Firestore)
  Map<String, int> inventory = {};

  // Animation controllers
  late AnimationController _opponentScoreAnimController;

  final GlobalKey<GameTimerState> _timerKey = GlobalKey();

  StreamSubscription? _roomSubscription;
  StreamSubscription? _playerSubscription;
  RoomModel? _currentRoom;
  bool _resultsShown = false;

  // Cached provider reference (safe for use in dispose)
  late AudioManager _audioManager;

  @override
  void initState() {
    super.initState();
    _audioManager = ref.read(audioManagerProvider);
    _opponentScoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initGame();
  }

  Future<void> _initGame() async {
    await ref.read(dictionaryServiceProvider).loadDictionary();
    _audioManager.playGameMusic();
    _loadPlayerInventory();
    _listenToRoom();
    _listenToEffects();

    // Track game start
    ref
        .read(analyticsProvider)
        .logEvent(
          name: 'game_start',
          parameters: {'mode': 'multiplayer', 'room_id': widget.roomId},
        );
  }

  void _loadPlayerInventory() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            inventory = Map<String, int>.from(
              data['inventory'] ??
                  {
                    'freeze': 1,
                    'reveal': 1,
                    'shuffle': 2,
                    'double_points': 1,
                    'bomb': 1,
                    'shield': 1,
                  },
            );
          });
        }
      }
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        debugPrint('Firestore unavailable, using default inventory or cache.');
      }
    }
  }

  void _listenToRoom() {
    final roomService = ref.read(roomServiceProvider);
    _roomSubscription = roomService.getRoomStream(widget.roomId).listen((room) {
      if (room != null) {
        setState(() {
          _currentRoom = room;
        });

        // Check if game ended
        if (room.status == RoomStatus.finished && !_resultsShown) {
          _resultsShown = true;
          _showGameResults(room);
        }
      }
    });
  }

  void _listenToEffects() {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) return;

          final data = snapshot.data()!;
          final activeEffects =
              data['activeEffects'] as Map<String, dynamic>? ?? {};

          // Check if there's an effect targeting current user
          if (activeEffects.containsKey(user.uid)) {
            final effect = activeEffects[user.uid] as Map<String, dynamic>;
            final effectType = effect['type'] as String;
            final endTime = (effect['endTime'] as Timestamp).toDate();

            // Check if effect is still active
            if (DateTime.now().isBefore(endTime)) {
              _applyEffect(effectType, endTime);
            }
          }
        });
  }

  void _applyEffect(String effectType, DateTime endTime) {
    final remainingSeconds = endTime.difference(DateTime.now()).inSeconds;

    switch (effectType) {
      case 'freeze':
        if (!hasShield) {
          setState(() {
            isFrozen = true;
            frozenSecondsRemaining = remainingSeconds;
          });
          ref.read(audioManagerProvider).playSfx(SoundEffect.powerUpReceived);

          frozenTimer?.cancel();
          frozenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (frozenSecondsRemaining > 0) {
              setState(() {
                frozenSecondsRemaining--;
              });
            } else {
              setState(() {
                isFrozen = false;
              });
              timer.cancel();
            }
          });
        } else {
          // Shield blocked the freeze
          setState(() {
            hasShield = false;
          });
          _showEffectBlocked('Freeze blocked by Shield!');
        }
        break;

      case 'bomb':
        if (!hasShield) {
          _applyBombEffect(remainingSeconds);
        } else {
          setState(() {
            hasShield = false;
          });
          _showEffectBlocked('Bomb blocked by Shield!');
        }
        break;
    }
  }

  void _applyBombEffect(int duration) {
    // Disable 5 random letters
    final indices = List.generate(gridSize * gridSize, (i) => i);
    indices.shuffle();
    setState(() {
      disabledIndices = indices.take(5).toList();
    });

    bombTimer?.cancel();
    bombTimer = Timer(Duration(seconds: duration), () {
      if (mounted) {
        setState(() {
          disabledIndices.clear();
        });
      }
    });
  }

  void _showEffectBlocked(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shield, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onLetterTap(int index) async {
    if (isFrozen) return;

    final hapticEnabled = ref.read(hapticEnabledProvider);
    if (hapticEnabled) {
      await Haptics.vibrate(HapticsType.light);
    }
    if (!mounted) return;

    ref.read(audioManagerProvider).playSfx(SoundEffect.letterSelect);

    setState(() {
      if (selectedIndices.isNotEmpty && selectedIndices.last == index) {
        selectedIndices.removeLast();
        currentWord = currentWord.substring(0, currentWord.length - 1);
      } else if (!selectedIndices.contains(index)) {
        selectedIndices.add(index);
        currentWord += _currentRoom!.gridLetters[index];
      }

      _updateWordValidation();
    });
  }

  void _onSwipeComplete(List<int> indices) {
    if (isFrozen || indices.isEmpty || _currentRoom == null) return;

    setState(() {
      selectedIndices = indices;
      currentWord = indices.map((i) => _currentRoom!.gridLetters[i]).join();
      _updateWordValidation();
    });
  }

  void _updateWordValidation() {
    if (_currentRoom == null) return;

    final minLength = _currentRoom!.wordLengthMin;
    if (currentWord.length == minLength) {
      final dictionaryService = ref.read(dictionaryServiceProvider);
      final user = ref.read(authStateProvider).value;

      // Check if word is valid and not already found by this player
      final playerWords = _currentRoom!.wordsFound[user?.uid] ?? [];
      isWordValid =
          dictionaryService.isValidWord(currentWord) &&
          !playerWords.contains(currentWord.toUpperCase());

      potentialScore = _calculateWordScore(currentWord);
    } else {
      isWordValid = false;
      potentialScore = null;
    }
  }

  int _calculateWordScore(String word) {
    final dictionaryService = ref.read(dictionaryServiceProvider);
    int baseScore = dictionaryService.getWordScore(word);

    if (isDoublePoints) {
      baseScore *= 2;
    }

    return baseScore;
  }

  Future<void> _submitWord() async {
    if (!isWordValid || _currentRoom == null) {
      ref.read(audioManagerProvider).playSfx(SoundEffect.wordInvalid);
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final wordScore = _calculateWordScore(currentWord);
    final roomService = ref.read(roomServiceProvider);

    final success = await roomService.submitWord(
      roomId: widget.roomId,
      playerId: user.uid,
      word: currentWord,
      score: wordScore,
    );
    if (!mounted) return;

    if (success) {
      ref.read(audioManagerProvider).playSfx(SoundEffect.wordSubmit);
      final hapticEnabled = ref.read(hapticEnabledProvider);
      if (hapticEnabled) {
        await Haptics.vibrate(HapticsType.success);
      }
      if (!mounted) return;
    } else {
      ref.read(audioManagerProvider).playSfx(SoundEffect.wordInvalid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word already found by another player!'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() {
      selectedIndices.clear();
      currentWord = "";
      isWordValid = false;
      potentialScore = null;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedIndices.clear();
      currentWord = "";
      isWordValid = false;
      potentialScore = null;
    });
  }

  Future<void> _usePowerUp(PowerUpType type) async {
    final count = inventory[type.name] ?? 0;
    if (count <= 0) return;

    final user = ref.read(authStateProvider).value;
    if (user == null || _currentRoom == null) return;

    ref.read(audioManagerProvider).playSfx(SoundEffect.powerUpUse);

    // Update local inventory
    setState(() {
      inventory[type.name] = count - 1;
    });

    // Update Firestore inventory (fire-and-forget with error handling)
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'inventory.${type.name}': FieldValue.increment(-1)},
      );
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable') rethrow;
      // Transient — local state is already decremented, will sync when back online
    }
    if (!mounted) return;

    final roomService = ref.read(roomServiceProvider);

    switch (type) {
      case PowerUpType.freeze:
        // Target a random opponent
        final opponents = _currentRoom!.playerIds
            .where((id) => id != user.uid)
            .toList();
        if (opponents.isNotEmpty) {
          opponents.shuffle();
          await roomService.usePowerUp(
            roomId: widget.roomId,
            odidUser: user.uid,
            targetPlayerId: opponents.first,
            powerUpType: 'freeze',
            duration: 10,
          );
          if (!mounted) return;
          _showPowerUpUsed('Freeze sent to opponent!');
        }
        break;

      case PowerUpType.bomb:
        final opponents = _currentRoom!.playerIds
            .where((id) => id != user.uid)
            .toList();
        if (opponents.isNotEmpty) {
          opponents.shuffle();
          await roomService.usePowerUp(
            roomId: widget.roomId,
            odidUser: user.uid,
            targetPlayerId: opponents.first,
            powerUpType: 'bomb',
            duration: 8,
          );
          if (!mounted) return;
          _showPowerUpUsed('Bomb sent to opponent!');
        }
        break;

      case PowerUpType.reveal:
        _revealWord();
        break;

      case PowerUpType.doublePoints:
        _activateDoublePoints();
        break;

      case PowerUpType.shield:
        setState(() {
          hasShield = true;
        });
        _showPowerUpUsed('Shield activated!');
        break;

      case PowerUpType.shuffle:
        // In multiplayer, shuffle only shows different arrangement locally
        // The actual grid stays the same for fairness
        _showPowerUpUsed('Personal view shuffled!');
        break;
    }
  }

  void _showPowerUpUsed(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _revealWord() {
    if (_currentRoom == null) return;

    final dictionaryService = ref.read(dictionaryServiceProvider);
    final user = ref.read(authStateProvider).value;
    // final playerWords = _currentRoom!.wordsFound[user?.uid] ?? [];
    isWordValid =
        dictionaryService.isValidWord(currentWord) &&
        !(_currentRoom!.wordsFound[user?.uid] ?? []).contains(
          currentWord.toUpperCase(),
        );
    final allFoundWords = _currentRoom!.wordsFound.values
        .expand((words) => words)
        .toSet();

    // Find a valid word
    for (int length = 5; length >= 3; length--) {
      for (
        int startIndex = 0;
        startIndex < _currentRoom!.gridLetters.length;
        startIndex++
      ) {
        final indices = _findConnectedWord(startIndex, length);
        if (indices != null) {
          final word = indices.map((i) => _currentRoom!.gridLetters[i]).join();
          if (dictionaryService.isValidWord(word) &&
              !allFoundWords.contains(word.toUpperCase())) {
            setState(() {
              selectedIndices = indices;
              currentWord = word;
              isWordValid = true;
              potentialScore = _calculateWordScore(word);
            });
            return;
          }
        }
      }
    }

    _showPowerUpUsed('No unrevealed words found!');
  }

  List<int>? _findConnectedWord(int startIndex, int targetLength) {
    if (_currentRoom == null) return null;

    List<int> path = [startIndex];
    while (path.length < targetLength) {
      int current = path.last;
      int row = current ~/ gridSize;
      int col = current % gridSize;

      List<int> neighbors = [];
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          int newRow = row + dr;
          int newCol = col + dc;
          if (newRow >= 0 &&
              newRow < gridSize &&
              newCol >= 0 &&
              newCol < gridSize) {
            int neighborIndex = newRow * gridSize + newCol;
            if (!path.contains(neighborIndex) &&
                !disabledIndices.contains(neighborIndex)) {
              neighbors.add(neighborIndex);
            }
          }
        }
      }

      if (neighbors.isEmpty) return null;
      neighbors.shuffle();
      path.add(neighbors.first);
    }

    return path;
  }

  void _activateDoublePoints() {
    setState(() {
      isDoublePoints = true;
    });

    doublePointsTimer?.cancel();
    doublePointsTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          isDoublePoints = false;
        });
      }
    });

    _showPowerUpUsed('Double points for 15 seconds!');
  }

  void _onTimerEnd() {
    ref.read(roomServiceProvider).endGame(widget.roomId);
  }

  void _updatePlayerStats(RoomModel room) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    // Determine winner
    String? winnerId;
    int highestScore = -1;
    room.scores.forEach((playerId, score) {
      if (score > highestScore) {
        highestScore = score;
        winnerId = playerId;
      }
    });

    final isWinner = winnerId == user.uid;
    final myScore = room.scores[user.uid] ?? 0;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'totalGamesPlayed': FieldValue.increment(1),
            'totalWins': FieldValue.increment(isWinner ? 1 : 0),
            'eloRating': FieldValue.increment(isWinner ? 25 : -10),
            'coins': FieldValue.increment(myScore),
          });
      debugPrint('Successfully updated own stats for ${user.uid}');

      final data = userDoc.data();
      if (data != null) {
        ref.read(leaderboardServiceProvider).syncEntry(
          userId: user.uid,
          displayName: data['displayName'] as String? ?? 'Player',
          eloRating: (data['eloRating'] as int? ?? 1000) + (isWinner ? 25 : -10),
          totalWins: (data['totalWins'] as int? ?? 0) + (isWinner ? 1 : 0),
          longestStreak: data['longestStreak'] as int? ?? 0,
          avatarUrl: data['avatarUrl'] as String? ?? '',
        );
      }
    } catch (e) {
      debugPrint('Failed to update own stats: $e');
    }
  }

  void _onTimerTick(int remaining) {
    if (remaining == 10) {
      ref.read(audioManagerProvider).playClutchMusic();
    }
  }

  void _showGameResults(RoomModel room) {
    _updatePlayerStats(room);

    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final myScore = room.scores[user.uid] ?? 0;
      ref
          .read(analyticsProvider)
          .logEvent(
            name: 'game_end',
            parameters: {
              'mode': 'multiplayer',
              'score': myScore,
              'result':
                  myScore >= room.scores.values.reduce((a, b) => a > b ? a : b)
                  ? 'win'
                  : 'loss',
            },
          );

      final notificationService = ref.read(notificationServiceProvider);
      notificationService.sendGameStartNotification(user.uid, room.roomCode);
    }

    ref.read(audioManagerProvider).stopBackgroundMusic();

    // Determine winner
    String? winnerId;
    int highestScore = 0;
    room.scores.forEach((playerId, score) {
      if (score > highestScore) {
        highestScore = score;
        winnerId = playerId;
      }
    });

    final currentUser = ref.read(authStateProvider).value;
    final isWinner = winnerId == currentUser?.uid;

    // Track game end
    if (currentUser != null) {
      final myScore = room.scores[currentUser.uid] ?? 0;
      final opponentId = room.playerIds.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => "",
      );
      final opponentScore = room.scores[opponentId] ?? 0;

      ref
          .read(analyticsProvider)
          .logEvent(
            name: 'game_end',
            parameters: {
              'mode': 'multiplayer',
              'score': myScore,
              'result': myScore > opponentScore
                  ? 'win'
                  : (myScore < opponentScore ? 'loss' : 'draw'),
            },
          );
    }

    if (isWinner) {
      ref.read(audioManagerProvider).playSfx(SoundEffect.gameWin);
    } else {
      ref.read(audioManagerProvider).playSfx(SoundEffect.gameLose);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: isWinner ? Colors.amber : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(isWinner ? 'Victory!' : 'Game Over'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Final Scores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...room.scores.entries.map((entry) {
              final isCurrentPlayer = entry.key == currentUser?.uid;
              final isWinnerPlayer = entry.key == winnerId;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(entry.key)
                    .get(),
                builder: (context, snapshot) {
                  String name = 'Player';
                  if (snapshot.hasData && snapshot.data!.exists) {
                    name =
                        (snapshot.data!.data()
                            as Map<String, dynamic>)['displayName'] ??
                        'Player';
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isWinnerPlayer
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentPlayer
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        if (isWinnerPlayer)
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$name ${isCurrentPlayer ? "(You)" : ""}',
                            style: TextStyle(
                              fontWeight: isCurrentPlayer
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Words found: ${room.wordsFound[user?.uid]?.length ?? 0}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context); // Back to lobby
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _playerSubscription?.cancel();
    frozenTimer?.cancel();
    doublePointsTimer?.cancel();
    bombTimer?.cancel();
    _opponentScoreAnimController.dispose();
    _audioManager.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoom == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ref.watch(authStateProvider).value;
    final myScore = _currentRoom!.scores[user?.uid] ?? 0;
    //  final myWordsCount = _currentRoom!.wordsFound[user?.uid]?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with timer and scores
            _buildHeader(user?.uid, myScore),

            // Opponent scores
            _buildOpponentScores(user?.uid),

            const SizedBox(height: 8),

            // Status indicators (frozen, shield, etc.)
            _buildStatusIndicators(),

            const Spacer(),

            // Word display
            WordDisplay(
              currentWord: currentWord,
              isValid: isWordValid,
              potentialScore: potentialScore,
            ),

            const SizedBox(height: 16),

            // Letter grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LetterGrid(
                letters: _currentRoom!.gridLetters,
                gridSize: gridSize,
                selectedIndices: selectedIndices,
                disabledIndices: disabledIndices,
                onLetterTap: _onLetterTap,
                onSwipeComplete: _onSwipeComplete,
                isEnabled: !isFrozen,
              ),
            ),

            const Spacer(),

            // Power-ups
            PowerUpBar(
              inventory: inventory,
              onPowerUpTap: _usePowerUp,
              isEnabled: !isFrozen,
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: currentWord.isNotEmpty && !isFrozen
                          ? _clearSelection
                          : null,
                      icon: const Icon(Icons.backspace),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: isWordValid && !isFrozen ? _submitWord : null,
                      icon: const Icon(Icons.check),
                      label: Text(
                        isWordValid ? 'Submit (+$potentialScore)' : 'Submit',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isWordValid ? Colors.green : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? odid, int myScore) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // My score
          Flexible(
            flex: 2,
            child: ScoreDisplay(
              score: myScore,
              isDoublePoints: isDoublePoints,
              playerName: 'You',
            ),
          ),

          const SizedBox(width: 8),

          // Timer
          GameTimer(
            key: _timerKey,
            totalSeconds: _currentRoom!.timeLimit,
            onTimerEnd: _onTimerEnd,
            onTick: _onTimerTick,
            isFrozen: isFrozen,
            frozenSecondsRemaining: frozenSecondsRemaining,
          ),

          const SizedBox(width: 8),

          // Round indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'R${_currentRoom!.currentRound}/${_currentRoom!.totalRounds}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentScores(String? myUid) {
    final opponents = _currentRoom!.playerIds
        .where((id) => id != myUid)
        .toList();

    if (opponents.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: opponents.length,
        itemBuilder: (context, index) {
          final odid = opponents[index];
          final score = _currentRoom!.scores[odid] ?? 0;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(odid)
                .get(),
            builder: (context, snapshot) {
              String name = 'Opponent';
              if (snapshot.hasData && snapshot.data!.exists) {
                name =
                    (snapshot.data!.data()
                        as Map<String, dynamic>)['displayName'] ??
                    'Opponent';
              }

              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: ScoreDisplay(
                  score: score,
                  playerName: name,
                  isOpponent: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFrozen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.lightBlue),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ac_unit, color: Colors.lightBlue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'FROZEN ${frozenSecondsRemaining}s',
                    style: const TextStyle(
                      color: Colors.lightBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(),

          if (hasShield) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'SHIELDED',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isDoublePoints) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.double_arrow, color: Colors.purple, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '2X POINTS',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(),
          ],
        ],
      ),
    );
  }
}
