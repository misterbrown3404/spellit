import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spellit/core/achievement_service.dart';
import 'package:spellit/models/achievement_model.dart';
import 'package:spellit/features/auth/auth_service.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view achievements')),
      );
    }

    final achievements = AchievementModel.predefinedAchievements();

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: StreamBuilder<List<AchievementModel>>(
        stream: ref.watch(achievementServiceProvider).getUnlockedAchievements(user.uid),
        builder: (context, snapshot) {
          final unlockedIds = snapshot.data?.map((e) => e.id).toSet() ?? <String>{};
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              final unlocked = unlockedIds.contains(a.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    _iconFor(a.icon),
                    color: unlocked ? Colors.amber : Colors.grey,
                    size: 32,
                  ),
                  title: Text(
                    a.title,
                    style: TextStyle(
                      fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(a.description),
                  trailing: unlocked
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.lock, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'military_tech':
        return Icons.military_tech;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'whatshot':
        return Icons.whatshot;
      case 'menu_book':
        return Icons.menu_book;
      default:
        return Icons.star;
    }
  }
}
