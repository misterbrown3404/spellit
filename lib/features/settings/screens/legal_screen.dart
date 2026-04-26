import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String type; // 'privacy' or 'terms'

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == 'privacy';
    final title = isPrivacy ? 'Privacy Policy' : 'Terms of Service';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: April 2026',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (isPrivacy) ..._buildPrivacyPolicy() else ..._buildTermsOfService(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrivacyPolicy() {
    return [
      _section('1. Introduction', 
        'SpellIt ("we", "us", or "our") respects your privacy. This Privacy Policy explains how we collect, use, and protect your information when you use our mobile application.'),
      
      _section('2. Information We Collect', 
        '• Account Data: Email address and display name (via Google/Firebase Auth).\n'
        '• Game Data: High scores, ELO rating, coins, power-ups, and game statistics.\n'
        '• Device Data: Basic device info for performance monitoring.'),
      
      _section('3. How We Use Data', 
        'We use your data to:\n'
        '• Synchronize your progress across devices.\n'
        '• Manage global leaderboards and matchmaking.\n'
        '• Improve game performance and fix bugs.'),
      
      _section('4. Data Retention & Deletion', 
        'We store your data as long as your account is active. You can delete your account and all associated data at any time via the Profile settings in the app. This action is permanent.'),
      
      _section('5. Third-Party Services', 
        'We use Google Firebase for authentication, database hosting, and analytics. Please refer to Google’s Privacy Policy for more details on how they handle data.'),
    ];
  }

  List<Widget> _buildTermsOfService() {
    return [
      _section('1. Acceptance of Terms', 
        'By downloading or using SpellIt, you agree to be bound by these Terms of Service. If you do not agree, please do not use the app.'),
      
      _section('2. Fair Play Policy', 
        'You agree not to:\n'
        '• Use bots, scripts, or cheats to gain an advantage.\n'
        '• Use offensive or inappropriate display names.\n'
        '• Harass or disrupt other players in multiplayer mode.'),
      
      _section('3. Virtual Items', 
        'Coins and Power-ups are virtual items with no real-world monetary value. They are non-transferable and non-refundable.'),
      
      _section('4. Account Termination', 
        'We reserve the right to suspend or terminate accounts that violate our Fair Play Policy or these Terms without prior notice.'),
      
      _section('5. Disclaimer', 
        'SpellIt is provided "as is" without warranties of any kind. We are not responsible for any data loss or service interruptions.'),
    ];
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
