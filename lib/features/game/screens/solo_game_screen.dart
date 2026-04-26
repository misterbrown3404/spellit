import 'dart:async';
import 'dart:math';
import 'package:spellit/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:spellit/core/setting_service.dart';
import '../../../core/audio_manager.dart';
import '../../../core/dictionary_service.dart';
import '../widgets/letter_grid.dart';
import '../widgets/game_timer.dart';
import '../widgets/power_up_bar.dart';
import '../widgets/score_display.dart';
import '../widgets/word_display.dart';
import '../../../models/power_up_model.dart';

class SoloGameScreen extends ConsumerStatefulWidget {
  final int timeLimit;
  final int minWordLength;

  const SoloGameScreen({
    super.key,
    this.timeLimit = 120,
    this.minWordLength = 3,
  });

  @override
  ConsumerState<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends ConsumerState<SoloGameScreen>
    with TickerProviderStateMixin {
  final int gridSize = 7;
  List<String> gridLetters = [];
  List<int> selectedIndices = [];
  String currentWord = "";
  int score = 0;
  List<String> wordsFound = [];
  bool isGameOver = false;
  bool _isLoading = true;
  
  // Power-up states
  Map<String, int> inventory = {
    'freeze': 1,
    'reveal': 1,
    'shuffle': 2,
    'double_points': 1,
    'bomb': 0,
  };
  bool isDoublePoints = false;
  Timer? doublePointsTimer;
  Map<int, int> letterMultipliers = {};
  
  // UI states
  bool isWordValid = false;
  bool isCheckingWord = false;
  int? potentialScore;
  
  // Animation keys
  final GlobalKey<GameTimerState> _timerKey = GlobalKey();

  // Cached provider references (safe for use in dispose)
  late AudioManager _audioManager;

  @override
  void initState() {
    super.initState();
    _audioManager = ref.read(audioManagerProvider);
    _initGame();
  }

  Future<void> _initGame() async {
    // Load dictionary
    await ref.read(dictionaryServiceProvider).loadDictionary();
    
    // Generate grid
    _generateGrid();
    
    // Generate random multipliers
    _generateMultipliers();
    
    // Play game music
    _audioManager.playGameMusic();
    
    // Track game start
    ref.read(analyticsProvider).logEvent(
      name: 'game_start',
      parameters: {
        'mode': 'solo',
        'time_limit': widget.timeLimit,
      },
    );
  }

  void _generateGrid() {
    const vowels = 'AEIOU';
    const commonConsonants = 'BCDFGHLMNPRST';
    const rareConsonants = 'JKQVWXYZ';
    Random rnd = Random();

    int totalCells = gridSize * gridSize;
    int vowelCount = (totalCells * 0.35).round();
    int commonCount = (totalCells * 0.50).round();

    List<String> grid = [];

    // Add vowels
    for (int i = 0; i < vowelCount; i++) {
      grid.add(vowels[rnd.nextInt(vowels.length)]);
    }

    // Add common consonants
    for (int i = 0; i < commonCount; i++) {
      grid.add(commonConsonants[rnd.nextInt(commonConsonants.length)]);
    }

    // Add rare consonants
    for (int i = grid.length; i < totalCells; i++) {
      grid.add(rareConsonants[rnd.nextInt(rareConsonants.length)]);
    }

    grid.shuffle(rnd);

    setState(() {
      gridLetters = grid;
      selectedIndices.clear();
      currentWord = "";
      _isLoading = false;
    });
  }

  void _generateMultipliers() {
    Random rnd = Random();
    letterMultipliers.clear();
    
    // Add 2-3 double point tiles
    int doubleCount = rnd.nextInt(2) + 2;
    for (int i = 0; i < doubleCount; i++) {
      int index = rnd.nextInt(gridSize * gridSize);
      if (!letterMultipliers.containsKey(index)) {
        letterMultipliers[index] = 2;
      }
    }
    
    // Add 1 triple point tile
    int tripleIndex = rnd.nextInt(gridSize * gridSize);
    while (letterMultipliers.containsKey(tripleIndex)) {
      tripleIndex = rnd.nextInt(gridSize * gridSize);
    }
    letterMultipliers[tripleIndex] = 3;
  }

  void _onLetterTap(int index) async {
    final hapticEnabled = ref.read(hapticEnabledProvider);
    if (hapticEnabled) {
      await Haptics.vibrate(HapticsType.light);
    }
    
    ref.read(audioManagerProvider).playSfx(SoundEffect.letterSelect);

    setState(() {
      if (selectedIndices.isNotEmpty && selectedIndices.last == index) {
        // Deselect last letter
        selectedIndices.removeLast();
        currentWord = currentWord.substring(0, currentWord.length - 1);
      } else if (!selectedIndices.contains(index)) {
        selectedIndices.add(index);
        currentWord += gridLetters[index];
      }
      
      _updateWordValidation();
    });
  }

  void _onSwipeComplete(List<int> indices) {
    if (indices.isEmpty) return;
    
    setState(() {
      selectedIndices = indices;
      currentWord = indices.map((i) => gridLetters[i]).join();
      _updateWordValidation();
    });
  }

  void _updateWordValidation() {
    if (currentWord.length >= widget.minWordLength) {
      final dictionaryService = ref.read(dictionaryServiceProvider);
      isWordValid = dictionaryService.isValidWord(currentWord) &&
          !wordsFound.contains(currentWord.toUpperCase());
      potentialScore = _calculateWordScore(currentWord);
    } else {
      isWordValid = false;
      potentialScore = null;
    }
  }

  int _calculateWordScore(String word) {
    final dictionaryService = ref.read(dictionaryServiceProvider);
    int baseScore = dictionaryService.getWordScore(word);
    
    // Apply multipliers from selected tiles
    int multiplier = 1;
    for (int index in selectedIndices) {
      if (letterMultipliers.containsKey(index)) {
        multiplier *= letterMultipliers[index]!;
      }
    }
    
    baseScore *= multiplier;
    
    // Apply double points power-up
    if (isDoublePoints) {
      baseScore *= 2;
    }
    
    return baseScore;
  }

  Future<void> _submitWord() async {
    if (currentWord.length < widget.minWordLength || !isWordValid) {
      ref.read(audioManagerProvider).playSfx(SoundEffect.wordInvalid);
      final hapticEnabled = ref.read(hapticEnabledProvider);
      if (hapticEnabled) {
        await Haptics.vibrate(HapticsType.error);
      }
      return;
    }

    final wordScore = _calculateWordScore(currentWord);

    setState(() {
      score += wordScore;
      wordsFound.add(currentWord.toUpperCase());
      selectedIndices.clear();
      currentWord = "";
      isWordValid = false;
      potentialScore = null;
    });

    ref.read(audioManagerProvider).playSfx(SoundEffect.wordSubmit);
    final hapticEnabled = ref.read(hapticEnabledProvider);
    if (hapticEnabled) {
      await Haptics.vibrate(HapticsType.success);
    }
  }

  void _clearSelection() {
    setState(() {
      selectedIndices.clear();
      currentWord = "";
      isWordValid = false;
      potentialScore = null;
    });
  }

  void _usePowerUp(PowerUpType type) {
    final count = inventory[type.name] ?? 0;
    if (count <= 0) return;

    ref.read(audioManagerProvider).playSfx(SoundEffect.powerUpUse);

    setState(() {
      inventory[type.name] = count - 1;
    });

    switch (type) {
      case PowerUpType.shuffle:
        _generateGrid();
        _generateMultipliers();
        break;
        
      case PowerUpType.reveal:
        _revealWord();
        break;
        
      case PowerUpType.doublePoints:
        _activateDoublePoints();
        break;
        
      case PowerUpType.freeze:
        // In solo mode, freeze adds time instead
        _timerKey.currentState?.addTime(15);
        break;
        
      default:
        break;
    }
  }

  void _revealWord() {
    // Find a valid word in the grid
    final dictionaryService = ref.read(dictionaryServiceProvider);
    
    // Simple reveal: find a 4-5 letter word by checking common patterns
    // This is a simplified version - a full implementation would use DFS
    for (int length = 5; length >= 3; length--) {
      for (int startIndex = 0; startIndex < gridLetters.length; startIndex++) {
        final indices = _findConnectedWord(startIndex, length);
        if (indices != null) {
          final word = indices.map((i) => gridLetters[i]).join();
          if (dictionaryService.isValidWord(word) &&
              !wordsFound.contains(word.toUpperCase())) {
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
    
    // If no word found, just shuffle
    _generateGrid();
  }

  List<int>? _findConnectedWord(int startIndex, int targetLength) {
    // Simple path finding - gets connected letters
    List<int> path = [startIndex];
    Random rnd = Random();
    
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
          if (newRow >= 0 && newRow < gridSize &&
              newCol >= 0 && newCol < gridSize) {
            int neighborIndex = newRow * gridSize + newCol;
            if (!path.contains(neighborIndex)) {
              neighbors.add(neighborIndex);
            }
          }
        }
      }
      
      if (neighbors.isEmpty) return null;
      path.add(neighbors[rnd.nextInt(neighbors.length)]);
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
  }

  void _onTimerEnd() {
    setState(() {
      isGameOver = true;
    });

    // Track game end
    ref.read(analyticsProvider).logEvent(
      name: 'game_end',
      parameters: {
        'mode': 'solo',
        'score': score,
        'words_found': wordsFound.length,
      },
    );
    
    ref.read(audioManagerProvider).stopBackgroundMusic();
    
    _showGameOverDialog();
  }

  void _onTimerTick(int remaining) {
    if (remaining == 10) {
      ref.read(audioManagerProvider).playClutchMusic();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Final Score: $score',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Words Found: ${wordsFound.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (wordsFound.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Your Words:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: wordsFound.map((word) => Chip(
                      label: Text(word),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    )).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to menu
            },
            child: const Text('Exit'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _restartGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      score = 0;
      wordsFound.clear();
      selectedIndices.clear();
      currentWord = "";
      isGameOver = false;
      isWordValid = false;
      potentialScore = null;
      isDoublePoints = false;
      inventory = {
        'freeze': 1,
        'reveal': 1,
        'shuffle': 2,
        'double_points': 1,
        'bomb': 0,
      };
    });
    
    _generateGrid();
    _generateMultipliers();
    _timerKey.currentState?.reset();
    _audioManager.playGameMusic();
  }

  @override
  void dispose() {
    doublePointsTimer?.cancel();
    _audioManager.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GameTimer(
          key: _timerKey,
          totalSeconds: widget.timeLimit,
          onTimerEnd: _onTimerEnd,
          onTick: _onTimerTick,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: ScoreDisplay(
              score: score,
              isDoublePoints: isDoublePoints,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Words found counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Words: ${wordsFound.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (wordsFound.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.list, size: 18),
                    label: const Text('View'),
                    onPressed: () => _showWordsList(),
                  ),
              ],
            ),
          ).animate().fadeIn(),

          const Spacer(),

          // Current word display
          WordDisplay(
            currentWord: currentWord,
            isValid: isWordValid,
            isChecking: isCheckingWord,
            potentialScore: potentialScore,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // Letter grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LetterGrid(
              letters: gridLetters,
              gridSize: gridSize,
              selectedIndices: selectedIndices,
              multipliers: letterMultipliers,
              onLetterTap: _onLetterTap,
              onSwipeComplete: _onSwipeComplete,
              isEnabled: !isGameOver,
            ),
          ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),

          const Spacer(),

          // Power-ups
          PowerUpBar(
            inventory: inventory,
            onPowerUpTap: _usePowerUp,
            isEnabled: !isGameOver,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: currentWord.isNotEmpty ? _clearSelection : null,
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
                    onPressed: isWordValid ? _submitWord : null,
                    icon: const Icon(Icons.check),
                    label: Text(isWordValid ? 'Submit (+$potentialScore)' : 'Submit'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isWordValid ? Colors.green : null,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showWordsList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Words Found (${wordsFound.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: wordsFound.map((word) => Chip(
                label: Text(word),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}