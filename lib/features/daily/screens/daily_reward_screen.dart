import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/auth_service.dart';
import '../../../core/audio_manager.dart';

class DailyRewardScreen extends ConsumerStatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  ConsumerState<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends ConsumerState<DailyRewardScreen> {
  int _currentStreak = 0;
  int _todayReward = 0;
  bool _hasClaimedToday = false;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _weeklyRewards = [
    {'day': 1, 'coins': 10, 'icon': Icons.monetization_on},
    {'day': 2, 'coins': 15, 'icon': Icons.monetization_on},
    {'day': 3, 'coins': 25, 'icon': Icons.monetization_on},
    {'day': 4, 'coins': 35, 'icon': Icons.monetization_on},
    {'day': 5, 'coins': 50, 'icon': Icons.monetization_on},
    {'day': 6, 'coins': 75, 'icon': Icons.monetization_on},
    {'day': 7, 'coins': 100, 'bonus': 'shuffle', 'icon': Icons.card_giftcard},
  ];

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        final lastLogin = (data['lastLoginDate'] as Timestamp?)?.toDate();
        final currentStreak = data['currentStreak'] ?? 0;
        final now = DateTime.now();

        bool hasClaimedToday = false;
        if (lastLogin != null) {
          hasClaimedToday = lastLogin.year == now.year &&
              lastLogin.month == now.month &&
              lastLogin.day == now.day;
        }

        final dayIndex = (currentStreak % 7);
        final todayReward = _weeklyRewards[dayIndex]['coins'] as int;

        setState(() {
          _currentStreak = currentStreak;
          _todayReward = todayReward;
          _hasClaimedToday = hasClaimedToday;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        print('Firestore unavailable while loading streak. Using defaults.');
        if (mounted) setState(() => _isLoading = false);
      } else {
        if (mounted) setState(() => _isLoading = false);
        rethrow;
      }
    }
  }

  Future<void> _claimReward() async {
    if (_hasClaimedToday) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final dayIndex = (_currentStreak % 7);
    final reward = _weeklyRewards[dayIndex];
    final coins = reward['coins'] as int;
    final bonus = reward['bonus'] as String?;

    try {
      final updateData = <String, dynamic>{
        'lastLoginDate': Timestamp.fromDate(DateTime.now()),
        'currentStreak': _currentStreak + 1,
        'coins': FieldValue.increment(coins),
      };

      if (bonus != null) {
        updateData['inventory.$bonus'] = FieldValue.increment(1);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      ref.read(audioManagerProvider).playSfx(SoundEffect.streakBonus);

      setState(() {
        _hasClaimedToday = true;
        _currentStreak++;
      });

      _showRewardClaimedDialog(coins, bonus);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to claim reward: $e')),
      );
    }
  }

  void _showRewardClaimedDialog(int coins, String? bonus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 64,
              color: Colors.amber,
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text(
              'Reward Claimed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                const SizedBox(width: 8),
                Text(
                  '+$coins',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
            if (bonus != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      '+1 ${bonus.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Rewards'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Streak display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.shade400,
                    Colors.red.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 64,
                    color: Colors.white,
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms),
                  const SizedBox(height: 8),
                  Text(
                    '$_currentStreak',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Day Streak',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 32),

            // Weekly rewards grid
            const Text(
              'Weekly Rewards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log in daily to earn increasing rewards!',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Rewards grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: 7,
              itemBuilder: (context, index) {
                final reward = _weeklyRewards[index];
                final dayInWeek = (_currentStreak % 7);
                final isCompleted = index < dayInWeek;
                final isCurrent = index == dayInWeek;
                final isLocked = index > dayInWeek;

                return _buildDayCard(
                  day: index + 1,
                  coins: reward['coins'] as int,
                  hasBonus: reward['bonus'] != null,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent && !_hasClaimedToday,
                  isLocked: isLocked || (isCurrent && _hasClaimedToday),
                ).animate().fadeIn(delay: (100 * index).ms).scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 300.ms,
                    );
              },
            ),

            const SizedBox(height: 32),

            // Claim button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _hasClaimedToday ? null : _claimReward,
                icon: Icon(_hasClaimedToday ? Icons.check : Icons.card_giftcard),
                label: Text(_hasClaimedToday
                    ? 'Claimed Today!'
                    : 'Claim $_todayReward Coins'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _hasClaimedToday ? Colors.green : null,
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (!_hasClaimedToday)
              Text(
                'Come back tomorrow to continue your streak!',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 32),

            // Milestone rewards
            _buildMilestoneSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required int day,
    required int coins,
    required bool hasBonus,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLocked,
  }) {
    Color backgroundColor;
    Color borderColor;
    Color contentColor;

    if (isCompleted) {
      backgroundColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green;
      contentColor = Colors.green;
    } else if (isCurrent) {
      backgroundColor = Colors.amber.withOpacity(0.2);
      borderColor = Colors.amber;
      contentColor = Colors.amber.shade700;
    } else {
      backgroundColor = Colors.grey.withOpacity(0.1);
      borderColor = Colors.grey.shade300;
      contentColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Day $day',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: contentColor,
            ),
          ),
          const SizedBox(height: 4),
          if (isCompleted)
            Icon(Icons.check_circle, color: contentColor, size: 24)
          else
            Icon(
              hasBonus ? Icons.card_giftcard : Icons.monetization_on,
              color: contentColor,
              size: 24,
            ),
          const SizedBox(height: 4),
          Text(
            '$coins',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneSection() {
    final milestones = [
      {'days': 7, 'reward': '100 Coins + Shuffle', 'icon': Icons.looks_one},
      {'days': 14, 'reward': '200 Coins + Reveal', 'icon': Icons.looks_two},
      {'days': 30, 'reward': '500 Coins + All Power-ups', 'icon': Icons.emoji_events},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestone Rewards',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...milestones.map((milestone) {
          final days = milestone['days'] as int;
          final isAchieved = _currentStreak >= days;
          final progress = (_currentStreak / days).clamp(0.0, 1.0);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isAchieved
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      milestone['icon'] as IconData,
                      color: isAchieved ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$days Day Streak',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          milestone['reward'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          color: isAchieved ? Colors.green : Colors.amber,
                        ),
                      ],
                    ),
                  ),
                  if (isAchieved)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
