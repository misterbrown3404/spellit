import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:spellit/core/setting_service.dart';
import 'package:spellit/features/auth/auth_service.dart';
import 'package:spellit/features/daily/screens/daily_reward_screen.dart';
import 'package:spellit/features/game/screens/solo_game_screen.dart';
import 'package:spellit/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:spellit/features/lobby/screens/lobby_screen.dart';
import 'package:spellit/features/profile/screens/profile_screen.dart';
import 'package:spellit/features/settings/screens/setting_screen.dart';
import 'package:spellit/features/shop/screens/shop_screen.dart';
import '../../../core/audio_manager.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _initAudio();
    _checkDailyReward();
  }

  Future<void> _initAudio() async {
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.init();
    
    if (settingsService.isMusicEnabled) {
      ref.read(audioManagerProvider).playMenuMusic();
    }
  }

  Future<void> _checkDailyReward() async {
    // Check if user needs to claim daily reward
    await Future.delayed(const Duration(milliseconds: 500));
    
    final player = ref.read(currentPlayerProvider).value;
    if (player != null) {
      final now = DateTime.now();
      final lastLogin = player.lastLoginDate;
      
      final isNewDay = lastLogin.year != now.year ||
          lastLogin.month != now.month ||
          lastLogin.day != now.day;
      
      if (isNewDay && mounted) {
        _showDailyRewardPrompt();
      }
    }
  }

  void _showDailyRewardPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Daily Reward!'),
          ],
        ),
        content: const Text('Your daily reward is ready to claim!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateTo(const DailyRewardScreen());
            },
            child: const Text('Claim Now'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) {
      _initAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
             colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SPELLIT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _navigateTo(const SettingsScreen()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Header with player info
                _buildHeader(player),

                const SizedBox(height: 32),

                // Logo and title
                _buildLogo(),

                const SizedBox(height: 48),

                // Main menu buttons
                _buildMenuButtons(),

                const SizedBox(height: 48),

                // Bottom navigation
                _buildBottomNav(),
                
                const SizedBox(height: 100), // Account for floating nav and bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue player) {
    return Row(
      children: [
        // Player info
        player.when(
          data: (p) => p != null
              ? GestureDetector(
                  onTap: () => _navigateTo(const ProfileScreen()),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          p.displayName.isNotEmpty
                              ? p.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                size: 14,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${p.eloRating}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const Spacer(),

        // Currency display
        player.when(
          data: (p) => p != null
              ? Row(
                  children: [
                    // Coins
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.coins}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Streak
                    GestureDetector(
                      onTap: () => _navigateTo(const DailyRewardScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${p.currentStreak}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Animated logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            size: 64,
            color: Colors.white,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 2000.ms,
            )
            .then()
            .shimmer(duration: 3000.ms),

        const SizedBox(height: 24),

        // Title
        const Text(
          'SPELLIT',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

        const SizedBox(height: 8),

        Text(
          'Battle with words',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildMenuButtons() {
    return Column(
      children: [
        // Solo Play
        _buildMenuButton(
          icon: Icons.person,
          label: 'SOLO PLAY',
          subtitle: 'Practice your skills',
          color: Colors.green,
          onTap: () => _showSoloGameOptions(),
        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2),

        const SizedBox(height: 12),

        // Multiplayer
        _buildMenuButton(
          icon: Icons.people,
          label: 'MULTIPLAYER',
          subtitle: 'Battle with friends',
          color: Colors.blue,
          onTap: () => _navigateTo(const LobbyScreen()),
        ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.2),

        const SizedBox(height: 12),

        /*
        // Quick Match (coming soon)
        _buildMenuButton(
          icon: Icons.flash_on,
          label: 'QUICK MATCH',
          subtitle: 'Find random opponent',
          color: Colors.orange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon!')),
            );
          },
          isComingSoon: true,
        ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2),
        */
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 1,
                            ),
                          ),
                          if (isComingSoon) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SOON',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            icon: Icons.card_giftcard,
            label: 'Daily',
            onTap: () => _navigateTo(const DailyRewardScreen()),
          ),
          _buildNavButton(
            icon: Icons.store,
            label: 'Shop',
            onTap: () => _navigateTo(const ShopScreen()),
          ),
          _buildNavButton(
            icon: Icons.leaderboard,
            label: 'Ranks',
            onTap: () => _navigateTo(const LeaderboardScreen()),
          ),
          _buildNavButton(
            icon: Icons.person,
            label: 'Profile',
            onTap: () => _navigateTo(const ProfileScreen()),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.5, curve: Curves.easeOutBack);
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        ref.read(audioManagerProvider).playSfx(SoundEffect.buttonClick);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showSoloGameOptions() {
    final settingsService = ref.read(settingsServiceProvider);
    int timeLimit = settingsService.defaultTimer;
    int minWordLength = settingsService.defaultWordLength;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Solo Game Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Time limit
              Text(
                'Time Limit: ${timeLimit ~/ 60}:${(timeLimit % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: timeLimit.toDouble(),
                min: 60,
                max: 300,
                divisions: 8,
                label: '${timeLimit}s',
                onChanged: (value) {
                  setModalState(() => timeLimit = value.round());
                },
              ),

              const SizedBox(height: 16),

              // Min word length
              Text(
                'Minimum Word Length: $minWordLength letters',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: minWordLength.toDouble(),
                min: 3,
                max: 6,
                divisions: 3,
                label: '$minWordLength',
                onChanged: (value) {
                  setModalState(() => minWordLength = value.round());
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Game'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateTo(SoloGameScreen(
                      timeLimit: timeLimit,
                      minWordLength: minWordLength,
                    ));
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
