import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/auth_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentFilter = 'all_time';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rating'),
            Tab(text: 'Wins'),
            Tab(text: 'Streak'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _currentFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all_time', child: Text('All Time')),
              const PopupMenuItem(value: 'weekly', child: Text('This Week')),
              const PopupMenuItem(value: 'daily', child: Text('Today')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList('eloRating'),
          _buildLeaderboardList('totalWins'),
          _buildLeaderboardList('longestStreak'),
        ],
      ),
    );
  }

  DateTime? get _filterCutoff {
    final now = DateTime.now();
    return switch (_currentFilter) {
      'weekly' => now.subtract(const Duration(days: 7)),
      'daily' => DateTime(now.year, now.month, now.day),
      _ => null, // 'all_time'
    };
  }

  Widget _buildLeaderboardList(String orderByField) {
    final user = ref.watch(authStateProvider).value;
    final cutoff = _filterCutoff;

    // Build query — apply date filter when not all_time
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .orderBy(orderByField, descending: true)
        .limit(100);

    if (cutoff != null) {
      query = query.where(
        'lastPlayedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No players yet'));
        }

        int? myRank;
        for (int i = 0; i < docs.length; i++) {
          if (docs[i].id == user?.uid) {
            myRank = i + 1;
            break;
          }
        }

        return Column(
          children: [
            if (myRank != null)
              Container(
                margin: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#$myRank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text('Keep playing to climb higher!'),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.trending_up,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isCurrentUser = doc.id == user?.uid;

                  return _buildLeaderboardItem(
                    rank: index + 1,
                    name: data['displayName'] ?? 'Player',
                    value: data[orderByField] ?? 0,
                    orderByField: orderByField,
                    isCurrentUser: isCurrentUser,
                    avatarUrl: data['avatarUrl'],
                  ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    required int value,
    required String orderByField,
    required bool isCurrentUser,
    String? avatarUrl,
  }) {
    Color? rankColor;
    IconData? rankIcon;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown.shade400;
      rankIcon = Icons.emoji_events;
    }

    final (valueLabel, valueIcon) = switch (orderByField) {
      'eloRating' => ('$value', Icons.stars),
      'totalWins' => ('$value wins', Icons.military_tech),
      'longestStreak' => ('$value days', Icons.local_fire_department),
      _ => ('$value', Icons.score),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentUser
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        leading: SizedBox(
          width: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (rank <= 3)
                Icon(rankIcon, color: rankColor, size: 40)
              else
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : null,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(valueIcon, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              valueLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
