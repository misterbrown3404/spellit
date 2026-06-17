import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spellit/core/setting_service.dart';
import 'package:spellit/core/tutorial_service.dart';
import 'package:spellit/features/tutorial/screens/tutorial_screen.dart';
import 'package:spellit/features/settings/screens/legal_screen.dart';
import '../../../core/audio_manager.dart';
import '../../../main.dart';
import '../../auth/auth_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late SettingsService _settingsService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = ref.read(settingsServiceProvider);
    await _settingsService.init();

    ref.read(musicEnabledProvider.notifier).state = _settingsService.isMusicEnabled;
    ref.read(sfxEnabledProvider.notifier).state = _settingsService.isSfxEnabled;
    ref.read(hapticEnabledProvider.notifier).state = _settingsService.isHapticEnabled;
    ref.read(darkModeProvider.notifier).state = _settingsService.isDarkMode;
    ref.read(musicVolumeProvider.notifier).state = _settingsService.musicVolume;
    ref.read(sfxVolumeProvider.notifier).state = _settingsService.sfxVolume;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final musicEnabled = ref.watch(musicEnabledProvider);
    final sfxEnabled = ref.watch(sfxEnabledProvider);
    final hapticEnabled = ref.watch(hapticEnabledProvider);
    final darkMode = ref.watch(darkModeProvider);
    final musicVolume = ref.watch(musicVolumeProvider);
    final sfxVolume = ref.watch(sfxVolumeProvider);
    final currentPlayer = ref.watch(currentPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound Settings
          _buildSectionHeader('Sound'),
          _buildSwitchTile(
            icon: Icons.music_note,
            title: 'Background Music',
            subtitle: 'Play music during gameplay',
            value: musicEnabled,
            onChanged: (value) async {
              ref.read(musicEnabledProvider.notifier).state = value;
              await _settingsService.setMusicEnabled(value);
              ref.read(audioManagerProvider).setMusicEnabled(value);
            },
          ),
          if (musicEnabled)
            _buildSliderTile(
              icon: Icons.volume_up,
              title: 'Music Volume',
              value: musicVolume,
              onChanged: (value) async {
                ref.read(musicVolumeProvider.notifier).state = value;
                await _settingsService.setMusicVolume(value);
                ref.read(audioManagerProvider).setMusicVolume(value);
              },
            ),
          _buildSwitchTile(
            icon: Icons.surround_sound,
            title: 'Sound Effects',
            subtitle: 'Play sounds for actions',
            value: sfxEnabled,
            onChanged: (value) async {
              ref.read(sfxEnabledProvider.notifier).state = value;
              await _settingsService.setSfxEnabled(value);
              ref.read(audioManagerProvider).setSfxEnabled(value);
            },
          ),
          if (sfxEnabled)
            _buildSliderTile(
              icon: Icons.volume_up,
              title: 'SFX Volume',
              value: sfxVolume,
              onChanged: (value) async {
                ref.read(sfxVolumeProvider.notifier).state = value;
                await _settingsService.setSfxVolume(value);
                ref.read(audioManagerProvider).setSfxVolume(value);
              },
            ),

          const SizedBox(height: 24),

          // Feedback Settings
          _buildSectionHeader('Feedback'),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on interactions',
            value: hapticEnabled,
            onChanged: (value) async {
              ref.read(hapticEnabledProvider.notifier).state = value;
              await _settingsService.setHapticEnabled(value);
            },
          ),

          const SizedBox(height: 24),

          // Appearance Settings
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            value: darkMode,
            onChanged: (value) async {
              ref.read(darkModeProvider.notifier).state = value;
              ref.read(themeProvider.notifier).state =
                  value ? ThemeMode.dark : ThemeMode.light;
              await _settingsService.setDarkMode(value);
            },
          ),

          const SizedBox(height: 24),

          // Game Defaults
          _buildSectionHeader('Game Defaults'),
          _buildNavigationTile(
            icon: Icons.timer,
            title: 'Default Timer',
            subtitle: '${_settingsService.defaultTimer} seconds',
            onTap: () => _showTimerPicker(),
          ),
          _buildNavigationTile(
            icon: Icons.text_fields,
            title: 'Minimum Word Length',
            subtitle: '${_settingsService.defaultWordLength} letters',
            onTap: () => _showWordLengthPicker(),
          ),

          const SizedBox(height: 24),

          // Notifications
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive game updates',
            value: _settingsService.isNotificationsEnabled,
            onChanged: (value) async {
              await _settingsService.setNotificationsEnabled(value);
              setState(() {});
            },
          ),

          const SizedBox(height: 24),

          // About & Support
          _buildSectionHeader('About & Support'),
          _buildNavigationTile(
            icon: Icons.help_outline,
            title: 'How to Play',
            subtitle: 'Learn the game rules',
            onTap: () => _showHowToPlay(),
          ),
          _buildNavigationTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalScreen(type: 'privacy'),
              ),
            ),
          ),
          _buildNavigationTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalScreen(type: 'terms'),
              ),
            ),
          ),
          _buildNavigationTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(),
          ),

_buildNavigationTile(
  icon: Icons.school,
  title: 'View Tutorial',
  subtitle: 'Learn how to play again',
  onTap: () async {
    final tutorialService = ref.read(tutorialServiceProvider);
    await tutorialService.resetTutorial();
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorialScreen(
            onComplete: () => Navigator.pop(context),
          ),
        ),
      );
    }
  },
),

          const SizedBox(height: 24),

          const SizedBox(height: 40),
        ],
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required Function(double) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Slider(
                    value: value,
                    onChanged: onChanged,
                    min: 0,
                    max: 1,
                  ),
                ],
              ),
            ),
            Text('${(value * 100).round()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.red.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        trailing: const Icon(Icons.chevron_right, color: Colors.red),
        onTap: onTap,
      ),
    );
  }

  void _showTimerPicker() {
    final options = [60, 90, 120, 180, 240, 300];
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Default Timer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...options.map((seconds) => ListTile(
                leading: const Icon(Icons.timer),
                title: Text('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'),
                trailing: _settingsService.defaultTimer == seconds
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await _settingsService.setDefaultTimer(seconds);
                  if (mounted) {
                    setState(() {});
                    Navigator.pop(context);
                  }
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showWordLengthPicker() {
    final options = [3, 4, 5, 6];
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Minimum Word Length',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...options.map((length) => ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text('$length letters'),
                trailing: _settingsService.defaultWordLength == length
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await _settingsService.setDefaultWordLength(length);
                  if (mounted) {
                    setState(() {});
                    Navigator.pop(context);
                  }
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎯 Objective',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Form as many valid English words as possible from the letter grid before time runs out.',
              ),
              SizedBox(height: 16),
              Text(
                '📝 Rules',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Tap or swipe letters to form words'),
              Text('• Letters must be adjacent (including diagonals)'),
              Text('• Each letter can only be used once per word'),
              Text('• Words must be at least 3 letters long'),
              Text('• Longer words earn more points'),
              SizedBox(height: 16),
              Text(
                '⚡ Power-ups',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Freeze: Stops opponent\'s timer'),
              Text('• Reveal: Shows a valid word'),
              Text('• Shuffle: Rearranges the grid'),
              Text('• Double Points: 2x score for 15 seconds'),
              Text('• Shield: Blocks one opponent attack'),
              Text('• Bomb: Disables opponent\'s letters'),
              SizedBox(height: 16),
              Text(
                '🏆 Scoring',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 3 letters: 30 points'),
              Text('• 4 letters: 50 points'),
              Text('• 5 letters: 80 points'),
              Text('• 6 letters: 130 points'),
              Text('• 7+ letters: 200+ points'),
              Text('• Rare letters (Q, Z, X, J) add bonus points'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'SpellIt',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.grid_view_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text(
          'A real-time multiplayer word game where you battle friends by forming words from a letter grid.',
        ),
        const SizedBox(height: 16),
        const Text('Made with ❤️ and Flutter'),
      ],
    );
  }
}