import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WordDisplay extends StatelessWidget {
  final String currentWord;
  final bool isValid;
  final bool isChecking;
  final int? potentialScore;

  const WordDisplay({
    super.key,
    required this.currentWord,
    this.isValid = false,
    this.isChecking = false,
    this.potentialScore,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (isChecking) {
      borderColor = Colors.grey;
    } else if (currentWord.isEmpty) {
      borderColor = Colors.transparent;
    } else if (isValid) {
      borderColor = Colors.green;
    } else {
      borderColor = Theme.of(context).colorScheme.outline;
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isValid
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isChecking)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (currentWord.isEmpty)
              Text(
                'Swipe or tap letters to form a word',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              )
            else ...[
              // Word letters with animation
              ...currentWord.split('').asMap().entries.map((entry) {
                return Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isValid
                            ? Colors.green
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        letterSpacing: 4,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (50 * entry.key).ms)
                    .slideX(begin: 0.2);
              }),

              // Potential score
              if (potentialScore != null && currentWord.length >= 3) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isValid
                        ? Colors.green.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$potentialScore',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isValid
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
