import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:spellit/core/setting_service.dart';
import 'package:spellit/features/auth/auth_service.dart';
import 'package:spellit/features/daily/screens/daily_reward_screen.dart';
import 'package:spellit/features/chat/screens/chat_screen.dart';
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
    await Future.delayed(const Duration(milliseconds: 500));

    final player = ref.read(currentPlayerProvider).value;
    if (player != null) {
      final now = DateTime.now();
      final lastLogin = player.lastLoginDate;

      final isNewDay =
          lastLogin.year != now.year ||
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
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.amber),
            SizedBox(width: 8),
            Text('Daily Reward!'),
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
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) {
      _initAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.8),
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
              colorScheme.primary.withValues(alpha: 0.07),
              colorScheme.secondary.withValues(alpha: 0.07),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Header with player info
                _buildHeader(player),

                const SizedBox(height: 20),

                // Logo and title
                _buildLogo(),

                const SizedBox(height: 28),

                // Main menu buttons
                _buildMenuButtons(),

                const Spacer(),

                // Bottom navigation
                _buildBottomNav(),

                const SizedBox(height: 16),
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
        player.when(
          data: (p) => p != null
              ? GestureDetector(
                  onTap: () => _navigateTo(const ProfileScreen()),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
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
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                size: 13,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 3),
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

        player.when(
          data: (p) => p != null
              ? Row(
                  children: [
                    _buildChip(
                      icon: Icons.monetization_on,
                      label: '${p.coins}',
                      color: Colors.amber,
                      bgColor: Colors.amber.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _navigateTo(const DailyRewardScreen()),
                      child: _buildChip(
                        icon: Icons.local_fire_department,
                        label: '${p.currentStreak}',
                        color: Colors.orange,
                        bgColor: Colors.orange.withValues(alpha: 0.15),
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

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        // Compact animated logo
        Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 38,
                color: Colors.white,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.04, 1.04),
              duration: 2000.ms,
            ),

        const SizedBox(width: 16),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SPELLIT',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
              ),
            ).animate().fadeIn(delay: 200.ms),
            Text(
              'Battle with words',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 350.ms),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButtons() {
    return Column(
      children: [
        _buildMenuButton(
          icon: Icons.person,
          label: 'SOLO PLAY',
          subtitle: 'Practice your skills',
          color: Colors.green,
          onTap: () => _showSoloGameOptions(),
        ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2),

        const SizedBox(height: 12),

        _buildMenuButton(
          icon: Icons.people,
          label: 'MULTIPLAYER',
          subtitle: 'Battle with friends',
          color: Colors.blue,
          onTap: () => _navigateTo(const LobbyScreen()),
        ).animate().fadeIn(delay: 620.ms).slideX(begin: 0.2),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
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
                              fontSize: 16,
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.45)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final colorScheme = Theme.of(context).colorScheme;

    final items = [
      _NavItem(
        icon: Icons.card_giftcard_outlined,
        activeIcon: Icons.card_giftcard,
        label: 'Daily',
        screen: const DailyRewardScreen(),
      ),
      _NavItem(
        icon: Icons.store_outlined,
        activeIcon: Icons.store,
        label: 'Shop',
        screen: const ShopScreen(),
      ),
      _NavItem(
        icon: Icons.leaderboard_outlined,
        activeIcon: Icons.leaderboard,
        label: 'Ranks',
        screen: const LeaderboardScreen(),
      ),
      _NavItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Chat',
        screen: const ChatScreen(),
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        screen: const ProfileScreen(),
      ),
    ];

    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              return Expanded(
                child: InkWell(
                  onTap: () {
                    ref
                        .read(audioManagerProvider)
                        .playSfx(SoundEffect.buttonClick);
                    _navigateTo(item.screen);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            size: 24,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )
        .animate()
        .fadeIn(delay: 800.ms)
        .slideY(begin: 0.4, curve: Curves.easeOutBack);
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

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
                    _navigateTo(
                      SoloGameScreen(
                        timeLimit: timeLimit,
                        minWordLength: minWordLength,
                      ),
                    );
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}
