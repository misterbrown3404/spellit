import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

class SettingsService {
  static const String _keyMusicEnabled = 'music_enabled';
  static const String _keySfxEnabled = 'sfx_enabled';
  static const String _keyHapticEnabled = 'haptic_enabled';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyMusicVolume = 'music_volume';
  static const String _keySfxVolume = 'sfx_volume';
  static const String _keyDefaultWordLength = 'default_word_length';
  static const String _keyDefaultTimer = 'default_timer';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Music
  bool get isMusicEnabled => _prefs?.getBool(_keyMusicEnabled) ?? true;
  Future<void> setMusicEnabled(bool value) async {
    await _prefs?.setBool(_keyMusicEnabled, value);
  }

  // SFX
  bool get isSfxEnabled => _prefs?.getBool(_keySfxEnabled) ?? true;
  Future<void> setSfxEnabled(bool value) async {
    await _prefs?.setBool(_keySfxEnabled, value);
  }

  // Haptic
  bool get isHapticEnabled => _prefs?.getBool(_keyHapticEnabled) ?? true;
  Future<void> setHapticEnabled(bool value) async {
    await _prefs?.setBool(_keyHapticEnabled, value);
  }

  // Dark Mode
  bool get isDarkMode => _prefs?.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(_keyDarkMode, value);
  }

  // Music Volume
  double get musicVolume => _prefs?.getDouble(_keyMusicVolume) ?? 0.5;
  Future<void> setMusicVolume(double value) async {
    await _prefs?.setDouble(_keyMusicVolume, value);
  }

  // SFX Volume
  double get sfxVolume => _prefs?.getDouble(_keySfxVolume) ?? 0.8;
  Future<void> setSfxVolume(double value) async {
    await _prefs?.setDouble(_keySfxVolume, value);
  }

  // Default Word Length
  int get defaultWordLength => _prefs?.getInt(_keyDefaultWordLength) ?? 3;
  Future<void> setDefaultWordLength(int value) async {
    await _prefs?.setInt(_keyDefaultWordLength, value);
  }

  // Default Timer
  int get defaultTimer => _prefs?.getInt(_keyDefaultTimer) ?? 120;
  Future<void> setDefaultTimer(int value) async {
    await _prefs?.setInt(_keyDefaultTimer, value);
  }

  // Notifications
  bool get isNotificationsEnabled =>
      _prefs?.getBool(_keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_keyNotificationsEnabled, value);
  }
}

// Riverpod state providers for reactive UI
final musicEnabledProvider = StateProvider<bool>((ref) => true);
final sfxEnabledProvider = StateProvider<bool>((ref) => true);
final hapticEnabledProvider = StateProvider<bool>((ref) => true);
final darkModeProvider = StateProvider<bool>((ref) => false);
final musicVolumeProvider = StateProvider<double>((ref) => 0.5);
final sfxVolumeProvider = StateProvider<double>((ref) => 0.8);
