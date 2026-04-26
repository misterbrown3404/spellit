
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tutorialServiceProvider = Provider((ref) => TutorialService());

class TutorialService {
  static const String _keyTutorialCompleted = 'tutorial_completed';
  static const String _keyTutorialStep = 'tutorial_step';
  
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isTutorialCompleted => _prefs?.getBool(_keyTutorialCompleted) ?? false;
  
  int get currentTutorialStep => _prefs?.getInt(_keyTutorialStep) ?? 0;

  Future<void> setTutorialCompleted(bool value) async {
    await _prefs?.setBool(_keyTutorialCompleted, value);
  }

  Future<void> setTutorialStep(int step) async {
    await _prefs?.setInt(_keyTutorialStep, step);
  }

  Future<void> resetTutorial() async {
    await _prefs?.setBool(_keyTutorialCompleted, false);
    await _prefs?.setInt(_keyTutorialStep, 0);
  }
}

// Provider for tutorial state
final tutorialCompletedProvider = StateProvider<bool>((ref) => false);
final showTutorialProvider = StateProvider<bool>((ref) => false);