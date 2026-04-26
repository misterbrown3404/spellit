import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spellit/features/lobby/screens/waiting_room_screenn.dart';
import 'package:spellit/features/settings/screens/setting_screen.dart';
import 'package:spellit/main_menu_screen.dart';
import '../features/auth/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/game/screens/solo_game_screen.dart';
import '../features/lobby/screens/lobby_screen.dart';
import '../features/game/screens/multiplayer_game_screen.dart';
import '../features/shop/screens/shop_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/daily/screens/daily_reward_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: '/solo',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return SoloGameScreen(
            timeLimit: params?['timeLimit'] ?? 120,
            minWordLength: params?['minWordLength'] ?? 3,
          );
        },
      ),
      GoRoute(
        path: '/lobby',
        builder: (context, state) => const LobbyScreen(),
      ),
      GoRoute(
        path: '/waiting/:roomId',
        builder: (context, state) => WaitingRoomScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/game/:roomId',
        builder: (context, state) => MultiplayerGameScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/shop',
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/daily',
        builder: (context, state) => const DailyRewardScreen(),
      ),
    ],
  );
});