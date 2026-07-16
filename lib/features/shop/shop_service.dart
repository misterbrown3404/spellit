import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/firebase_providers.dart';
import '../../core/network_utils.dart';
import '../../models/power_up_model.dart';

final shopServiceProvider = Provider((ref) {
  return ShopService(firestore: ref.watch(firebaseFirestoreProvider));
});

class ShopPlayerData {
  const ShopPlayerData({
    required this.coins,
    required this.gems,
    required this.inventory,
  });

  final int coins;
  final int gems;
  final Map<String, int> inventory;

  static const empty = ShopPlayerData(coins: 0, gems: 0, inventory: {});
}

class ShopPurchaseResult {
  const ShopPurchaseResult({
    required this.coins,
    required this.inventory,
  });

  final int coins;
  final Map<String, int> inventory;
}

class ShopException implements Exception {
  const ShopException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ShopService {
  ShopService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<ShopPlayerData> loadPlayerData(String userId) async {
    final doc = await AppNetwork.execute<DocumentSnapshot<Map<String, dynamic>>>(
      operationName: 'loadShopPlayerData',
      action: () => _firestore.collection('users').doc(userId).get(),
    );

    if (!doc.exists) return ShopPlayerData.empty;

    final data = doc.data() ?? {};
    return ShopPlayerData(
      coins: data['coins'] as int? ?? 0,
      gems: data['gems'] as int? ?? 0,
      inventory: Map<String, int>.from(data['inventory'] as Map? ?? {}),
    );
  }

  Future<ShopPurchaseResult> purchasePowerUp({
    required String userId,
    required PowerUpModel powerUp,
  }) {
    final userRef = _firestore.collection('users').doc(userId);

    return AppNetwork.execute<ShopPurchaseResult>(
      operationName: 'purchasePowerUp',
      action: () => _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw const ShopException('Player profile not found.');
        }

        final data = snapshot.data() ?? {};
        final coins = data['coins'] as int? ?? 0;
        if (coins < powerUp.coinPrice) {
          throw const ShopException('Not enough coins.');
        }

        final inventory = Map<String, int>.from(data['inventory'] as Map? ?? {});
        final updatedCoins = coins - powerUp.coinPrice;
        final updatedInventory = {
          ...inventory,
          powerUp.id: (inventory[powerUp.id] ?? 0) + 1,
        };

        transaction.update(userRef, {
          'coins': updatedCoins,
          'inventory.${powerUp.id}': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return ShopPurchaseResult(
          coins: updatedCoins,
          inventory: updatedInventory,
        );
      }),
    );
  }
}
