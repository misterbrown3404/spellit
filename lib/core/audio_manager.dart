import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioManagerProvider = Provider((ref) => AudioManager());

class AudioManager {
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.8;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;

  Future<void> playBackgroundMusic(String assetPath) async {
    if (!_isMusicEnabled) return;
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.setVolume(_musicVolume);
    await _bgMusicPlayer.play(AssetSource(assetPath));
  }

  Future<void> playMenuMusic() async {
    await playBackgroundMusic('audio/menu_music.mp3');
  }

  Future<void> playGameMusic() async {
    await playBackgroundMusic('audio/game_music.mp3');
  }

  Future<void> playClutchMusic() async {
    // Intense music for last 10 seconds
    await playBackgroundMusic('audio/clutch_music.wav');
  }

  Future<void> stopBackgroundMusic() async {
    await _bgMusicPlayer.stop();
  }

  Future<void> pauseBackgroundMusic() async {
    await _bgMusicPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (_isMusicEnabled) {
      await _bgMusicPlayer.resume();
    }
  }

  // Sound Effects
  Future<void> playSfx(SoundEffect effect) async {
    if (!_isSfxEnabled) return;
    await _sfxPlayer.setVolume(_sfxVolume);
    
    String assetPath = switch (effect) {
      SoundEffect.letterSelect => 'audio/sfx/letter_tap.wav',
      SoundEffect.wordSubmit => 'audio/sfx/word_submit.wav',
      SoundEffect.wordInvalid => 'audio/sfx/invalid.wav',
      SoundEffect.powerUpUse => 'audio/sfx/power_up.wav',
      SoundEffect.powerUpReceived => 'audio/sfx/power_received.wav',
      SoundEffect.timerWarning => 'audio/sfx/timer_warning.wav',
      SoundEffect.gameWin => 'audio/sfx/victory.mp3',
      SoundEffect.gameLose => 'audio/sfx/defeat.wav',
      SoundEffect.buttonClick => 'audio/sfx/click.wav',
      SoundEffect.coinCollect => 'audio/sfx/coin.wav',
      SoundEffect.streakBonus => 'audio/sfx/streak.wav',
    };
    
    await _sfxPlayer.play(AssetSource(assetPath));
  }

  void setMusicEnabled(bool enabled) {
    _isMusicEnabled = enabled;
    if (!enabled) {
      _bgMusicPlayer.pause();
    } else {
      _bgMusicPlayer.resume();
    }
  }

  void setSfxEnabled(bool enabled) {
    _isSfxEnabled = enabled;
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume;
    _bgMusicPlayer.setVolume(volume);
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume;
  }

  void dispose() {
    _bgMusicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}

enum SoundEffect {
  letterSelect,
  wordSubmit,
  wordInvalid,
  powerUpUse,
  powerUpReceived,
  timerWarning,
  gameWin,
  gameLose,
  buttonClick,
  coinCollect,
  streakBonus,
}