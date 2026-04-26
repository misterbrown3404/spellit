import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spellit/features/tutorial/widget/gameplay_tutorial.dart';
import 'package:spellit/features/tutorial/widget/tutorial_overlay.dart';
import '../../../core/tutorial_service.dart';


class TutorialScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const TutorialScreen({super.key, required this.onComplete});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  bool _showGameplayTutorial = false;

  void _onIntroComplete() {
    setState(() => _showGameplayTutorial = true);
  }

  void _onTutorialComplete() async {
    final tutorialService = ref.read(tutorialServiceProvider);
    await tutorialService.setTutorialCompleted(true);
    widget.onComplete();
  }

  void _onSkip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Tutorial?'),
        content: const Text(
          'You can always view the tutorial again from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Tutorial'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _onTutorialComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showGameplayTutorial) {
      return GameplayTutorial(onComplete: _onTutorialComplete);
    }

    return TutorialOverlay(
      onComplete: _onIntroComplete,
      onSkip: _onSkip,
    );
  }
}