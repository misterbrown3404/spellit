
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<TutorialStep> _steps = [
    TutorialStep(
      title: 'Welcome to SpellIt! 🎮',
      description: 'The ultimate word battle game!\n\nForm words faster than your opponents to claim victory.',
      icon: Icons.grid_view_rounded,
      color: Colors.purple,
      imagePath: null,
    ),
    TutorialStep(
      title: 'The Letter Grid 🔤',
      description: 'You\'ll see a 7x7 grid of letters.\n\nTap ANY letters to form words - they don\'t need to be next to each other!',
      icon: Icons.apps,
      color: Colors.blue,
      imagePath: null,
    ),
    TutorialStep(
      title: 'Forming Words ✍️',
      description: 'Tap letters in any order to spell a word.\n\nThe number on each selected letter shows the order you picked them.',
      icon: Icons.touch_app,
      color: Colors.green,
      imagePath: null,
    ),
    TutorialStep(
      title: 'Submit Your Word ✅',
      description: 'When your word is valid, the Submit button turns GREEN.\n\nTap it to score points!',
      icon: Icons.check_circle,
      color: Colors.teal,
      imagePath: null,
    ),
    TutorialStep(
      title: 'Scoring System 🏆',
      description: 'Longer words = More points!\n\n• 3 letters: 30 pts\n• 4 letters: 50 pts\n• 5 letters: 80 pts\n• 6 letters: 130 pts\n• 7+ letters: 200+ pts',
      icon: Icons.stars,
      color: Colors.amber,
      imagePath: null,
    ),
    TutorialStep(
      title: 'Bonus Letters ⭐',
      description: 'Difficult letters give bonus points!\n\nQ, Z, X, J, K = +30 points each\n\nLook for tiles with 2x or 3x multipliers!',
      icon: Icons.auto_awesome,
      color: Colors.orange,
      imagePath: null,
    ),
    TutorialStep(
      title: 'Power-Ups ⚡',
      description: '❄️ Freeze - Stop opponent\'s timer\n💡 Reveal - Show a valid word\n🔀 Shuffle - Mix up the grid\n2️⃣x Double - 2x points for 15s\n🛡️ Shield - Block attacks\n💣 Bomb - Disable opponent letters',
      icon: Icons.bolt,
      color: Colors.red,
      imagePath: null,
    ),
    TutorialStep(
      title: 'Beat the Clock ⏱️',
      description: 'Find as many words as you can before time runs out!\n\nIn multiplayer, the player with the highest score wins.',
      icon: Icons.timer,
      color: Colors.indigo,
      imagePath: null,
    ),
    TutorialStep(
      title: 'You\'re Ready! 🚀',
      description: 'Start with Solo Mode to practice, then challenge friends in Multiplayer!\n\nGood luck and have fun!',
      icon: Icons.celebration,
      color: Colors.pink,
      imagePath: null,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: widget.onSkip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
            ),

            // Progress indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(_steps.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? _steps[_currentStep].color
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ).animate().fadeIn(delay: 200.ms),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentStep = index),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _buildStepContent(step, index);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Back button
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text('Back', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),

                  const SizedBox(width: 16),

                  // Next/Start button
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _nextStep,
                      icon: Icon(
                        _currentStep == _steps.length - 1
                            ? Icons.play_arrow
                            : Icons.arrow_forward,
                      ),
                      label: Text(
                        _currentStep == _steps.length - 1 ? 'Start Playing!' : 'Next',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _steps[_currentStep].color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(TutorialStep step, int index) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animated background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: step.color,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: const Duration(seconds: 2),
              ),

          const SizedBox(height: 40),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

          const SizedBox(height: 24),

          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 32),

          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${index + 1} of ${_steps.length}',
              style: TextStyle(
                color: step.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? imagePath;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.imagePath,
  });
}