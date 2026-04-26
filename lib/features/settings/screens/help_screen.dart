
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            icon: Icons.grid_view_rounded,
            title: 'The Grid',
            content: 'You\'ll see a 7x7 grid of letters. Your goal is to form valid English words by selecting letters.',
            color: Colors.blue,
          ),

          _buildSection(
            context,
            icon: Icons.touch_app,
            title: 'Selecting Letters',
            content: 'Tap ANY letters on the grid to form a word. Letters don\'t need to be next to each other!\n\nThe number on each selected letter shows the order you picked them.',
            color: Colors.green,
          ),

          _buildSection(
            context,
            icon: Icons.check_circle,
            title: 'Submitting Words',
            content: 'When your word is valid:\n• The Submit button turns GREEN\n• Tap Submit to score points\n• Tap Clear to start over',
            color: Colors.teal,
          ),

          _buildSection(
            context,
            icon: Icons.stars,
            title: 'Scoring',
            content: '''Points by word length:
• 3 letters: 30 pts
• 4 letters: 50 pts
• 5 letters: 80 pts
• 6 letters: 130 pts
• 7+ letters: 200+ pts

Bonus letters (Q, Z, X, J, K): +30 pts each
Tile multipliers: 2x or 3x points!''',
            color: Colors.amber,
          ),

          _buildSection(
            context,
            icon: Icons.bolt,
            title: 'Power-Ups',
            content: '''❄️ Freeze - Stop opponent's timer (10s)
💡 Reveal - Show a valid word
🔀 Shuffle - Rearrange the grid
2️⃣x Double - 2x points for 15s
🛡️ Shield - Block one attack
💣 Bomb - Disable 5 opponent letters''',
            color: Colors.red,
          ),

          _buildSection(
            context,
            icon: Icons.people,
            title: 'Multiplayer',
            content: '''• All players see the same grid
• First to submit a word claims it
• Highest score when time ends wins
• Use power-ups strategically!''',
            color: Colors.purple,
          ),

          _buildSection(
            context,
            icon: Icons.lightbulb,
            title: 'Tips',
            content: '''• Look for common endings: -ING, -ED, -LY
• Find difficult letters (Q, Z) and build around them
• Save power-ups for crucial moments
• Speed up in the final 30 seconds!''',
            color: Colors.orange,
          ),

          const SizedBox(height: 32),

          // Quick reference card
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Reference',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickRef('Minimum word length', '3 letters'),
                _buildQuickRef('Grid size', '7 x 7'),
                _buildQuickRef('Letters must touch?', 'NO - tap any letters!'),
                _buildQuickRef('Same letter twice?', 'Only if on different tiles'),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildQuickRef(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}