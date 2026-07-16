import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spellit/core/di/firebase_providers.dart';
import 'package:spellit/core/logging/app_logger.dart';
import 'package:spellit/core/router.dart';
import 'package:spellit/core/setting_service.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/tutorial_service.dart';
import 'core/audio_manager.dart';
import 'core/network_status.dart';
import 'core/notification_service.dart';
import 'package:spellit/features/auth/auth_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        details.exception,
        stackTrace: details.stack,
        operation: 'Flutter framework',
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppLogger.error(
        error,
        stackTrace: stackTrace,
        operation: 'Platform dispatcher',
      );
      return true;
    };

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore offline persistence for production.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    await _applyPreferredOrientations();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(const ProviderScope(child: SpellItApp()));
  }, (error, stackTrace) {
    AppLogger.error(
      error,
      stackTrace: stackTrace,
      operation: 'Uncaught zone',
    );
  });
}

/// Locks portrait only on handheld phones. Tablets, foldables, desktop and web
/// keep every orientation so responsive layouts can adapt. If the display
/// metrics are not yet available (size unknown), we default to locking mobile
/// devices to portrait rather than silently leaving them unlocked.
Future<void> _applyPreferredOrientations() async {
  final isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  if (!isMobile) return;

  final view = PlatformDispatcher.instance.views.first;
  final logicalSize = view.physicalSize / view.devicePixelRatio;
  final shortestSide = logicalSize.shortestSide;

  // Treat < 600dp shortest side as a phone; unknown size defaults to portrait.
  if (shortestSide <= 0 || shortestSide < 600) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// App-level analytics accessor used by feature screens. Delegates to the
/// dependency-injected Firebase analytics provider.
final analyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => ref.watch(firebaseAnalyticsProvider),
);

class SpellItApp extends ConsumerStatefulWidget {
  const SpellItApp({super.key});

  @override
  ConsumerState<SpellItApp> createState() => _SpellItAppState();
}

class _SpellItAppState extends ConsumerState<SpellItApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audioManager = ref.read(audioManagerProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      audioManager.pauseBackgroundMusic();
    } else if (state == AppLifecycleState.resumed) {
      audioManager.resumeBackgroundMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      await settingsService.init();

      ref.read(themeProvider.notifier).state =
          settingsService.isDarkMode ? ThemeMode.dark : ThemeMode.light;

      final tutorialService = ref.read(tutorialServiceProvider);
      await tutorialService.init();
      ref.read(tutorialCompletedProvider.notifier).state =
          tutorialService.isTutorialCompleted;

      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.init();
    } catch (e) {
      AppLogger.error(e, operation: 'App initialization');
    } finally {
      if (mounted) {
        ref.read(appInitializedProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        ref.read(authServiceProvider).syncLeaderboardForCurrentUser();
      }
    });
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SpellIt',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) => NetworkStatusOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
