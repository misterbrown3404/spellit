import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GameplayTutorial extends StatefulWidget {
  final VoidCallback onComplete;

  const GameplayTutorial({super.key, required this.onComplete});

  @override
  State<GameplayTutorial> createState() => _GameplayTutorialState();
}

class _GameplayTutorialState extends State<GameplayTutorial> {
  int _step = 0;
  final List<int> _selectedIndices = [];
  String _currentWord = '';
  bool _showSuccess = false;

  // Sample grid for tutorial
  final List<String> _tutorialGrid = [
    'C',
    'A',
    'T',
    'S',
    'D',
    'O',
    'G',
    'H',
    'E',
    'L',
    'P',
    'W',
    'O',
    'R',
    'P',
    'L',
    'A',
    'Y',
    'G',
    'A',
    'M',
    'W',
    'O',
    'R',
    'D',
    'S',
    'E',
    'N',
    'F',
    'U',
    'N',
    'B',
    'A',
    'T',
    'H',
    'R',
    'E',
    'A',
    'D',
    'I',
    'N',
    'G',
    'B',
    'O',
    'O',
    'K',
    'S',
    'T',
    'Y',
  ];

  final List<TutorialInstruction> _instructions = [
    TutorialInstruction(
      title: 'Tap to Select Letters',
      description: 'Try tapping the letters C, A, T to spell "CAT"',
      targetWord: 'CAT',
      targetIndices: [0, 1, 2],
      highlightIndices: [0, 1, 2],
    ),
    TutorialInstruction(
      title: 'Select Any Letters!',
      description: 'Now spell "PLAY" - notice letters don\'t need to touch!',
      targetWord: 'PLAY',
      targetIndices: [14, 15, 16, 17],
      highlightIndices: [14, 15, 16, 17],
    ),
    TutorialInstruction(
      title: 'Find Longer Words',
      description: 'Spell "WORDS" for more points! Look anywhere on the grid.',
      targetWord: 'WORDS',
      targetIndices: [21, 22, 23, 24, 11],
      highlightIndices: [21, 22, 23, 24, 11],
    ),
    TutorialInstruction(
      title: 'You Got It! 🎉',
      description:
          'Now you know how to play! Remember:\n• Tap any letters\n• Longer words = more points\n• Beat the clock!',
      targetWord: '',
      targetIndices: [],
      highlightIndices: [],
    ),
  ];

  void _onLetterTap(int index) {
    if (_step >= _instructions.length - 1) return;

    setState(() {
      if (_selectedIndices.contains(index)) {
        // Deselect
        final removeIndex = _selectedIndices.indexOf(index);
        _selectedIndices.removeAt(removeIndex);
        _currentWord = _selectedIndices.map((i) => _tutorialGrid[i]).join();
      } else {
        // Select
        _selectedIndices.add(index);
        _currentWord = _selectedIndices.map((i) => _tutorialGrid[i]).join();
      }
    });

    // Check if word matches target
    final targetWord = _instructions[_step].targetWord;
    if (_currentWord.toUpperCase() == targetWord.toUpperCase()) {
      _showSuccessAndAdvance();
    }
  }

  void _showSuccessAndAdvance() {
    setState(() => _showSuccess = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSuccess = false;
          _selectedIndices.clear();
          _currentWord = '';
          _step++;
        });
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
      _currentWord = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final instruction = _instructions[_step];
    final isLastStep = _step >= _instructions.length - 1;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Step ${_step + 1}/${_instructions.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: const Text('Skip Tutorial'),
                  ),
                ],
              ),
            ),

            // Instruction
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    instruction.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    instruction.description,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Current word display
            Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: _showSuccess
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showSuccess ? Colors.green : Colors.white24,
                  width: 2,
                ),
              ),
              child: Center(
                child: _showSuccess
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Great! "$_currentWord"',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ).animate().scale()
                    : Text(
                        _currentWord.isEmpty
                            ? 'Tap letters below'
                            : _currentWord,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _currentWord.isEmpty
                              ? Colors.white38
                              : Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Tutorial Grid — Expanded takes all remaining space
            if (!isLastStep)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                      itemCount: 49,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedIndices.contains(index);
                        final isHighlighted = instruction.highlightIndices
                            .contains(index);
                        final letter = _tutorialGrid[index];

                        return GestureDetector(
                              onTap: () => _onLetterTap(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : isHighlighted
                                      ? Colors.amber.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isHighlighted && !isSelected
                                      ? Border.all(
                                          color: Colors.amber,
                                          width: 2,
                                        )
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        bottom: 2,
                                        left: 2,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${_selectedIndices.indexOf(index) + 1}',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                            .animate(
                              target: isHighlighted && !isSelected ? 1 : 0,
                            )
                            .shimmer(
                              duration: const Duration(seconds: 2),
                              color: Colors.amber.withValues(alpha: 0.3),
                            );
                      },
                    ),
                  ),
                ),
              )
            else
              const Spacer(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: isLastStep
                  ? FilledButton.icon(
                      onPressed: widget.onComplete,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'Start Playing!',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: Colors.green,
                      ),
                    ).animate().scale()
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearSelection,
                            icon: const Icon(
                              Icons.backspace,
                              color: Colors.white70,
                            ),
                            label: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.white70),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.white24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed:
                                _currentWord.toUpperCase() ==
                                    instruction.targetWord.toUpperCase()
                                ? _showSuccessAndAdvance
                                : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Submit'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  _currentWord.toUpperCase() ==
                                      instruction.targetWord.toUpperCase()
                                  ? Colors.green
                                  : null,
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
}

class TutorialInstruction {
  final String title;
  final String description;
  final String targetWord;
  final List<int> targetIndices;
  final List<int> highlightIndices;

  const TutorialInstruction({
    required this.title,
    required this.description,
    required this.targetWord,
    required this.targetIndices,
    required this.highlightIndices,
  });
}
