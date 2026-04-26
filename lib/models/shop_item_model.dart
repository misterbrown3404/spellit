enum ShopCategory { powerUps, avatars, themes, coins }

class ShopItemModel {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final ShopCategory category;
  final int coinPrice;
  final int gemPrice;
  final bool isPremium;
  final int quantity; // For coin packs

  const ShopItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.category,
    this.coinPrice = 0,
    this.gemPrice = 0,
    this.isPremium = false,
    this.quantity = 1,
  });
}