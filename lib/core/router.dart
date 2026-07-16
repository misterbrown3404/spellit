import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
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
import '../features/profile/screens/profile_screen.dart';
import '../features/tutorial/screens/tutorial_screen.dart';
import 'di/firebase_providers.dart';
import 'tutorial_service.dart';

/// True once the one-time app bootstrap (settings, tutorial state,
/// notifications) has finished. Drives the initial splash gate.
final appInitializedProvider = StateProvider<bool>((ref) => false);

/// Bridges Riverpod state changes into a [Listenable] that GoRouter can use to
/// re-run its redirect logic without rebuilding the whole router (which would
/// otherwise reset navigation state).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(appInitializedProvider, (_, __) => notifyListeners());
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(tutorialCompletedProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final initialized = _ref.read(appInitializedProvider);

    // Hold on the splash screen until bootstrap completes.
    if (!initialized) {
      return location == '/splash' ? null : '/splash';
    }

    final authState = _ref.read(authStateProvider);

    // Wait for the first auth emission before deciding where to go.
    if (authState.isLoading) {
      return location == '/splash' ? null : '/splash';
    }

    final loggedIn = authState.value != null;
    final tutorialDone = _ref.read(tutorialCompletedProvider);

    if (!loggedIn) {
      return location == '/login' ? null : '/login';
    }

    if (!tutorialDone) {
      return location == '/tutorial' ? null : '/tutorial';
    }

    // Fully ready: bounce away from the pre-app gates.
    if (location == '/login' ||
        location == '/splash' ||
        location == '/tutorial') {
      return '/';
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [
      FirebaseAnalyticsObserver(analytics: ref.read(firebaseAnalyticsProvider)),
    ],
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/tutorial',
        builder: (context, state) => TutorialScreen(
          onComplete: () =>
              ref.read(tutorialCompletedProvider.notifier).state = true,
        ),
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
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

/// Branded splash shown while the app bootstraps and auth resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SPELLIT',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Fallback screen for unknown/deep-link routes.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_rounded, size: 64),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'The page you were looking for is unavailable.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
