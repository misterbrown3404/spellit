enum PowerUpType { freeze, reveal, shuffle, doublePoints, shield, bomb }

class PowerUpModel {
  final String id;
  final PowerUpType type;
  final String name;
  final String description;
  final String iconPath;
  final int coinPrice;
  final int gemPrice;
  final int duration; // in seconds (for timed effects)

  const PowerUpModel({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.coinPrice,
    this.gemPrice = 0,
    this.duration = 0,
  });

  static const List<PowerUpModel> allPowerUps = [
    PowerUpModel(
      id: 'freeze',
      type: PowerUpType.freeze,
      name: 'Time Freeze',
      description: 'Freeze opponent\'s timer for 10 seconds',
      iconPath: 'assets/icons/freeze.png',
      coinPrice: 50,
      duration: 10,
    ),
    PowerUpModel(
      id: 'reveal',
      type: PowerUpType.reveal,
      name: 'Word Reveal',
      description: 'Reveals a valid word on the grid',
      iconPath: 'assets/icons/reveal.png',
      coinPrice: 75,
    ),
    PowerUpModel(
      id: 'shuffle',
      type: PowerUpType.shuffle,
      name: 'Grid Shuffle',
      description: 'Shuffles all letters on the grid',
      iconPath: 'assets/icons/shuffle.png',
      coinPrice: 30,
    ),
    PowerUpModel(
      id: 'double_points',
      type: PowerUpType.doublePoints,
      name: 'Double Points',
      description: 'Double points for next 15 seconds',
      iconPath: 'assets/icons/double.png',
      coinPrice: 100,
      duration: 15,
    ),
    PowerUpModel(
      id: 'shield',
      type: PowerUpType.shield,
      name: 'Shield',
      description: 'Block one opponent power-up',
      iconPath: 'assets/icons/shield.png',
      coinPrice: 60,
    ),
    PowerUpModel(
      id: 'bomb',
      type: PowerUpType.bomb,
      name: 'Letter Bomb',
      description: 'Remove 5 random letters from opponent\'s grid for 8 seconds',
      iconPath: 'assets/icons/bomb.png',
      coinPrice: 80,
      duration: 8,
    ),
  ];
}