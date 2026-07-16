import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_service.dart';
import '../leaderboard_service.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final userId = user?.uid;

    final leaderboardAsync = ref.watch(leaderboardWithUserProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: SingleChildScrollView(
        child: leaderboardAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Couldn\'t refresh leaderboard',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('Top Players', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Center(child: Text('No players yet')),
              ],
            ),
          ),
          data: (data) {
            final topEntries = data.topEntries;
            final currentUserEntry = data.currentUserEntry;
            final currentUserInTop = data.currentUserInTop;
            final hasAnyError = data.hasAnyError;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAnyError)
                    const Text(
                      'Couldn\'t refresh leaderboard',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Top Players',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (topEntries.isEmpty && !hasAnyError)
                    const Center(child: Text('No players yet'))
                  else if (topEntries.isEmpty && hasAnyError)
                    const Center(child: Text('No players yet'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topEntries.length,
                      itemBuilder: (context, index) {
                        final entry = topEntries[index];
                        return _buildLeaderboardItem(
                          context: context,
                          rank: index + 1,
                          name: entry.displayName,
                          value: entry.value,
                          orderByField: 'eloRating',
                          isCurrentUser: entry.userId == userId,
                          avatarUrl: entry.avatarUrl,
                        );
                      },
                    ),

                  if (!currentUserInTop && currentUserEntry != null && topEntries.isNotEmpty)
                    const Divider(height: 32),
                  if (!currentUserInTop && currentUserEntry != null && topEntries.isNotEmpty)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.person_pin_circle, size: 40),
                        title: Text(
                          currentUserEntry.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text('Your position'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${currentUserEntry.value}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (userId == null && topEntries.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          'Sign in to see your rank',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required BuildContext context,
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
      color: isCurrentUser ? Theme.of(context).colorScheme.primaryContainer : null,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(fontWeight: isCurrentUser ? FontWeight.bold : null),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
            Flexible(
              child: Text(
                valueLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
