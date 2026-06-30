import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/auth_service.dart';
import '../../../core/theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName(String uid) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': newName,
      });
      if (mounted) setState(() => _isEditingName = false);
    } on FirebaseException catch (e) {
      if (mounted && e.code != 'unavailable') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ref.read(authServiceProvider).signOut();
              if (!mounted) return; // ← State's mounted is correct here
              Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data including progress, coins, and achievements will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // close dialog before await
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (!mounted) return; // ← guard after await
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully')),
                );
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return; // ← guard in catch too
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(currentPlayerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: playerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (player) {
          if (player == null) {
            final authUser = ref.watch(authStateProvider).value;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Profile Setup Needed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We couldn\'t find your profile data. If you just signed up, it might take a moment to sync.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () async {
                        if (authUser != null) {
                          // Try to fix it by ensuring the document exists
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(authUser.uid)
                              .set({
                                'displayName': authUser.displayName ?? 'Player',
                                'email': authUser.email ?? '',
                                'lastLoginDate': FieldValue.serverTimestamp(),
                                'coins': 100,
                                'eloRating': 1000,
                                'totalGamesPlayed': 0,
                                'totalWins': 0,
                                'currentStreak': 0,
                                'longestStreak': 0,
                                'inventory': {
                                  'freeze': 0,
                                  'reveal': 0,
                                  'shuffle': 1,
                                },
                              }, SetOptions(merge: true));
                          ref.invalidate(currentPlayerProvider);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Sync Profile'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _confirmSignOut,
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          }

          final initials = player.displayName.isNotEmpty
              ? player.displayName[0].toUpperCase()
              : '?';
          final winRate = player.totalGamesPlayed > 0
              ? (player.totalWins / player.totalGamesPlayed * 100).round()
              : 0;

          if (!_isEditingName) {
            _nameController.text = player.displayName;
          }

          return CustomScrollView(
            slivers: [
              // ── Hero SliverAppBar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // Avatar
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.25),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),

                          const SizedBox(height: 12),

                          // Name / Edit Row
                          _isEditingName
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _nameController,
                                          autofocus: true,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _isSaving
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : IconButton(
                                              icon: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _saveDisplayName(player.odid),
                                            ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () => setState(
                                          () => _isEditingName = false,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      player.displayName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _isEditingName = true),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),

                          const SizedBox(height: 4),

                          // Email
                          Text(
                            player.email.isNotEmpty
                                ? player.email
                                : 'Guest Account',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ELO Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${player.eloRating} ELO',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Body content ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Streak Banner ──────────────────────────────────
                    _buildStreakBanner(
                      player.currentStreak,
                      player.longestStreak,
                      colorScheme,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                    const SizedBox(height: 16),

                    // ── Stats Grid ─────────────────────────────────────
                    _sectionTitle('Statistics'),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _statCard(
                          'Games Played',
                          '${player.totalGamesPlayed}',
                          Icons.sports_esports,
                          Colors.blue,
                          colorScheme,
                        ),
                        _statCard(
                          'Total Wins',
                          '${player.totalWins}',
                          Icons.emoji_events,
                          Colors.amber,
                          colorScheme,
                        ),
                        _statCard(
                          'Win Rate',
                          '$winRate%',
                          Icons.trending_up,
                          Colors.green,
                          colorScheme,
                        ),
                        _statCard(
                          'Longest Streak',
                          '${player.longestStreak}d',
                          Icons.local_fire_department,
                          Colors.orange,
                          colorScheme,
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 20),

                    // ── Wallet ─────────────────────────────────────────
                    _sectionTitle('Wallet'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _walletCard(
                            'Coins',
                            '${player.coins}',
                            Icons.monetization_on,
                            Colors.amber,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _walletCard(
                            'Gems',
                            '${player.gems}',
                            Icons.diamond,
                            Colors.purple,
                            colorScheme,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 20),

                    // ── Inventory ──────────────────────────────────────
                    if (player.inventory.isNotEmpty) ...[
                      _sectionTitle('Power-Up Inventory'),
                      const SizedBox(height: 10),
                      _buildInventoryRow(
                        player.inventory,
                        colorScheme,
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 16),

                    // ── Account Actions ────────────────────────────────
                    _sectionTitle('Account Management'),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.logout,
                              color: Colors.orange,
                            ),
                            title: const Text('Sign Out'),
                            onTap: _confirmSignOut,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            title: const Text('Delete Account'),
                            subtitle: const Text(
                              'Permanently delete your profile data',
                            ),
                            onTap: _confirmDeleteAccount,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStreakBanner(int current, int longest, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Streak',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '$current day${current == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Best',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '$longest',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletCard(
    String label,
    String amount,
    IconData icon,
    Color color,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(Map<String, int> inventory, ColorScheme cs) {
    final icons = {
      'freeze': (Icons.ac_unit, Colors.lightBlue),
      'reveal': (Icons.lightbulb, Colors.amber),
      'shuffle': (Icons.shuffle, Colors.green),
      'double_points': (Icons.double_arrow, Colors.purple),
      'shield': (Icons.shield, Colors.teal),
      'bomb': (Icons.flash_on, Colors.red),
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: inventory.entries.map((entry) {
        final meta = icons[entry.key];
        final icon = meta?.$1 ?? Icons.star;
        final color = meta?.$2 ?? AppTheme.primaryColor;
        final name = entry.key.replaceAll('_', ' ');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                name[0].toUpperCase() + name.substring(1),
                style: TextStyle(fontSize: 13, color: cs.onSurface),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '×${entry.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
