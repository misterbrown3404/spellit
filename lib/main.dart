import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spellit/core/setting_service.dart';
import 'package:spellit/features/auth/screens/login_screen.dart';
import 'package:spellit/main_menu_screen.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/tutorial_service.dart';
import 'features/auth/auth_service.dart';
import 'features/tutorial/screens/tutorial_screen.dart';
import 'core/audio_manager.dart';
import 'core/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence for production
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: SpellItApp()));
}

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final analyticsProvider = Provider((ref) => FirebaseAnalytics.instance);

class SpellItApp extends ConsumerStatefulWidget {
  const SpellItApp({super.key});

  @override
  ConsumerState<SpellItApp> createState() => _SpellItAppState();
}

class _SpellItAppState extends ConsumerState<SpellItApp>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _showTutorial = false;

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

      if (settingsService.isDarkMode) {
        ref.read(themeProvider.notifier).state = ThemeMode.dark;
      } else {
        ref.read(themeProvider.notifier).state = ThemeMode.light;
      }

      final tutorialService = ref.read(tutorialServiceProvider);
      await tutorialService.init();

      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.init();

      if (mounted) {
        setState(() {
          _showTutorial = !tutorialService.isTutorialCompleted;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _onTutorialComplete() {
    setState(() {
      _showTutorial = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'SpellIt',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: ref.read(analyticsProvider)),
      ],
      home: !_isInitialized
          ? const SplashScreen()
          : authState.when(
              data: (user) {
                if (user == null) {
                  return const LoginScreen();
                }

                if (_showTutorial) {
                  return TutorialScreen(onComplete: _onTutorialComplete);
                }

                return const MainMenuScreen();
              },
              loading: () {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  if (_showTutorial) {
                    return TutorialScreen(onComplete: _onTutorialComplete);
                  }
                  return const MainMenuScreen();
                }
                return const LoginScreen();
              },
              error: (_, __) => const LoginScreen(),
            ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
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
