import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:spellit/core/setting_service.dart';
import 'package:spellit/features/auth/auth_service.dart';
import 'package:spellit/features/daily/screens/daily_reward_screen.dart';
//import 'package:spellit/features/chat/screens/chat_screen.dart';
import 'package:spellit/features/game/screens/solo_game_screen.dart';
import 'package:spellit/features/lobby/screens/lobby_screen.dart';
import 'package:spellit/features/profile/screens/profile_screen.dart';
import 'package:spellit/features/settings/screens/setting_screen.dart';
import '../../../core/audio_manager.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  // Bottom nav route -> index map, kept in one place so both the
  // GoRouter path lookup and the tap handler stay in sync.
  static const List<String> _navPaths = [
    '/daily',
    '/shop',
    '/leaderboard',
    '/profile',
  ];

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: Colors.amber),
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
      extendBody: true, // let content flow behind the floating glass nav
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.secondary.withValues(alpha: 0.85),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SPELLIT',
          style: TextStyle(
            fontWeight: FontWeight.w800,
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
      bottomNavigationBar: _buildFloatingNav(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.secondary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: 110,
                ), // clears floating nav
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildHeader(player),
                        const SizedBox(height: 20),
                        _buildLogo(),
                        const SizedBox(height: 28),
                        _buildMenuButtons(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue player) {
    return Row(
      children: [
        Expanded(
          child: player.when(
            data: (p) => p != null
                ? GestureDetector(
                    onTap: () => _navigateTo(const ProfileScreen()),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 19,
                            backgroundColor: Theme.of(context).cardColor,
                            child: Text(
                              p.displayName.isNotEmpty
                                  ? p.displayName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.stars_rounded,
                                    size: 13,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '${p.eloRating}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SizedBox(width: 8),

        player.when(
          data: (p) => p != null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      _buildChip(
                        icon: Icons.monetization_on_rounded,
                        label: '${p.coins}',
                        color: Colors.amber,
                        bgColor: Colors.amber.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _navigateTo(const DailyRewardScreen()),
                        child: _buildChip(
                          icon: Icons.local_fire_department_rounded,
                          label: '${p.currentStreak}',
                          color: Colors.orange,
                          bgColor: Colors.orange.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
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

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'SPELLIT',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 5,
                  ),
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
        ),
      ],
    );
  }

  Widget _buildMenuButtons() {
    return Column(
      children: [
        _buildMenuButton(
          icon: Icons.person_rounded,
          label: 'SOLO PLAY',
          subtitle: 'Practice your skills',
          color: Colors.green,
          onTap: () => _showSoloGameOptions(),
        ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2),

        const SizedBox(height: 12),

        _buildMenuButton(
          icon: Icons.people_alt_rounded,
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
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Floating glassmorphic bottom nav with a sliding active-tab indicator.
  // ---------------------------------------------------------------------
  Widget _buildFloatingNav() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentPath = GoRouterState.of(context).matchedLocation;
    final activeIndex = _navPaths.indexOf(currentPath);

    final items = [
      _NavItem(
        icon: Icons.card_giftcard_outlined,
        activeIcon: Icons.card_giftcard_rounded,
        label: 'Daily',
        path: '/daily',
      ),
      _NavItem(
        icon: Icons.store_outlined,
        activeIcon: Icons.store_rounded,
        label: 'Shop',
        path: '/shop',
      ),
      _NavItem(
        icon: Icons.leaderboard_outlined,
        activeIcon: Icons.leaderboard_rounded,
        label: 'Ranks',
        path: '/leaderboard',
      ),
      // _NavItem(
      //   icon: Icons.chat_bubble_outline,
      //   activeIcon: Icons.chat_bubble_rounded,
      //   label: 'Chat',
      //   path: '/chat',
      // ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        path: '/profile',
      ),
    ];

    return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.4 : 0.12,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / items.length;
                    final showIndicator = activeIndex >= 0;

                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Sliding pill indicator behind the active tab.
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          left: showIndicator ? tabWidth * activeIndex : 0,
                          top: 8,
                          bottom: 8,
                          width: tabWidth,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: showIndicator ? 1 : 0,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Tap targets + icons/labels.
                        Row(
                          children: items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isActive = index == activeIndex;

                            return SizedBox(
                              width: tabWidth,
                              child: InkWell(
                                onTap: () {
                                  ref
                                      .read(audioManagerProvider)
                                      .playSfx(SoundEffect.buttonClick);
                                  if (!isActive) context.push(item.path);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isActive ? item.activeIcon : item.icon,
                                        size: 22,
                                        color: isActive
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(item.label, maxLines: 1),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms)
        .slideY(begin: 0.4, curve: Curves.easeOutBack);
  }

  void _showSoloGameOptions() {
    final settingsService = ref.read(settingsServiceProvider);
    int timeLimit = settingsService.defaultTimer;
    int minWordLength = settingsService.defaultWordLength;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Game'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
