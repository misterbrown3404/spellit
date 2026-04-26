import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dictionaryServiceProvider = Provider((ref) => DictionaryService());

class DictionaryService {
  Set<String> _validWords = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadDictionary() async {
    if (_isLoaded) return;
    
    try {
      // Load from assets - you'll need to add a words.txt file
      final String wordsData = await rootBundle.loadString('assets/words.txt');
      _validWords = wordsData
          .split('\n')
          .map((word) => word.trim().toUpperCase())
          .where((word) => word.length >= 3 && word.length <= 15)
          .toSet();
      _isLoaded = true;
    } catch (e) {
      // Fallback to basic English words
      _validWords = _getBasicWords();
      _isLoaded = true;
    }
  }

  bool isValidWord(String word) {
    return _validWords.contains(word.toUpperCase());
  }

  int getWordScore(String word) {
    int baseScore = word.length;
    
    // Bonus for longer words
    if (word.length >= 7) {
      baseScore += 15;
    } else if (word.length >= 6) {
      baseScore += 10;
    } else if (word.length >= 5) {
      baseScore += 5;
    } else if (word.length >= 4) {
      baseScore += 2;
    }
    
    // Bonus for difficult letters
    const difficultLetters = {'Q', 'Z', 'X', 'J', 'K'};
    for (var char in word.toUpperCase().split('')) {
      if (difficultLetters.contains(char)) {
        baseScore += 3;
      }
    }
    
    return baseScore * 10;
  }

  // Find valid words in the grid (for reveal power-up)
  List<String> findValidWordsInGrid(List<String> grid, int gridSize, {int minLength = 3}) {
    List<String> foundWords = [];
    // Implement word search algorithm here
    // This is a simplified version - you'd want DFS/BFS for connected letters
    return foundWords;
  }

  Set<String> _getBasicWords() {
    // Fallback basic words
    return {
      'THE', 'AND', 'FOR', 'ARE', 'BUT', 'NOT', 'YOU', 'ALL', 'CAN', 'HAD',
      'HER', 'WAS', 'ONE', 'OUR', 'OUT', 'DAY', 'GET', 'HAS', 'HIM', 'HIS',
      'HOW', 'ITS', 'MAY', 'NEW', 'NOW', 'OLD', 'SEE', 'WAY', 'WHO', 'BOY',
      'DID', 'OWN', 'SAY', 'SHE', 'TOO', 'USE', 'WORD', 'PLAY', 'GAME',
      // Add more words...
    };
  }
}