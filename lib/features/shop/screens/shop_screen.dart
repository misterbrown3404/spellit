
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/power_up_model.dart';
import '../../auth/auth_service.dart';
import '../../../core/audio_manager.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _playerCoins = 0;
  int _playerGems = 0;
  Map<String, int> _playerInventory = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _playerCoins = data['coins'] ?? 0;
          _playerGems = data['gems'] ?? 0;
          _playerInventory = Map<String, int>.from(data['inventory'] ?? {});
        });
      }
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        // Transient error — silently ignore, app will show defaults
        print('Firestore unavailable while loading shop data. Using defaults.');
      } else {
        rethrow;
      }
    }
  }

  Future<void> _purchaseItem(PowerUpModel powerUp) async {
    if (_playerCoins < powerUp.coinPrice) {
      _showInsufficientFunds();
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${powerUp.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIconForPowerUp(powerUp.type), size: 48),
            const SizedBox(height: 16),
            Text(powerUp.description),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${powerUp.coinPrice}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'coins': FieldValue.increment(-powerUp.coinPrice),
        'inventory.${powerUp.id}': FieldValue.increment(1),
      });

      ref.read(audioManagerProvider).playSfx(SoundEffect.coinCollect);

      setState(() {
        _playerCoins -= powerUp.coinPrice;
        _playerInventory[powerUp.id] = (_playerInventory[powerUp.id] ?? 0) + 1;
      });

      _showPurchaseSuccess(powerUp.name);
    } catch (e) {
      _showError('Purchase failed. Please try again.');
    }
  }

  void _showInsufficientFunds() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not enough coins!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showPurchaseSuccess(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName purchased successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  IconData _getIconForPowerUp(PowerUpType type) {
    return switch (type) {
      PowerUpType.freeze => Icons.ac_unit,
      PowerUpType.reveal => Icons.lightbulb,
      PowerUpType.shuffle => Icons.shuffle,
      PowerUpType.doublePoints => Icons.double_arrow,
      PowerUpType.shield => Icons.shield,
      PowerUpType.bomb => Icons.flash_on,
    };
  }

  Color _getColorForPowerUp(PowerUpType type) {
    return switch (type) {
      PowerUpType.freeze => Colors.lightBlue,
      PowerUpType.reveal => Colors.amber,
      PowerUpType.shuffle => Colors.green,
      PowerUpType.doublePoints => Colors.purple,
      PowerUpType.shield => Colors.teal,
      PowerUpType.bomb => Colors.red,
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Power-ups'),
            Tab(text: 'Coins'),
            Tab(text: 'Premium'),
          ],
        ),
        actions: [
          // Coins display
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_playerCoins',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Gems display
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond, color: Colors.purple, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_playerGems',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPowerUpsTab(),
          _buildCoinsTab(),
          _buildPremiumTab(),
        ],
      ),
    );
  }

  Widget _buildPowerUpsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: PowerUpModel.allPowerUps.length,
      itemBuilder: (context, index) {
        final powerUp = PowerUpModel.allPowerUps[index];
        final owned = _playerInventory[powerUp.id] ?? 0;
        final canAfford = _playerCoins >= powerUp.coinPrice;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: canAfford ? () => _purchaseItem(powerUp) : null,
            child: Column(
              children: [
                // Header with icon
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getColorForPowerUp(powerUp.type).withOpacity(0.3),
                        _getColorForPowerUp(powerUp.type).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _getIconForPowerUp(powerUp.type),
                        size: 48,
                        color: _getColorForPowerUp(powerUp.type),
                      ),
                      // Owned badge
                      if (owned > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x$owned',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          powerUp.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          powerUp.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Price
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: canAfford ? Colors.amber : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${powerUp.coinPrice}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: canAfford ? null : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).scale(
              begin: const Offset(0.8, 0.8),
              duration: 300.ms,
            );
      },
    );
  }

  Widget _buildCoinsTab() {
    final coinPacks = [
      {'coins': 500, 'price': '\$0.99', 'bonus': 0},
      {'coins': 1200, 'price': '\$1.99', 'bonus': 200},
      {'coins': 2500, 'price': '\$3.99', 'bonus': 500},
      {'coins': 6500, 'price': '\$9.99', 'bonus': 1500},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coinPacks.length,
      itemBuilder: (context, index) {
        final pack = coinPacks[index];
        final coins = pack['coins'] as int;
        final bonus = pack['bonus'] as int;
        final price = pack['price'] as String;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade300, Colors.amber.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (bonus > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+$bonus BONUS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text('${coins + bonus} coins total'),
            trailing: FilledButton(
              onPressed: () {
                // Implement in-app purchase
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
              child: Text(price),
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
      },
    );
  }

  Widget _buildPremiumTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade300,
                    Colors.purple.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.diamond,
                size: 80,
                color: Colors.white,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'SPELLIT PREMIUM',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock the full experience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            _buildPremiumFeature(Icons.block, 'No Ads'),
            _buildPremiumFeature(Icons.monetization_on, 'Double Daily Coins'),
            _buildPremiumFeature(Icons.card_giftcard, 'Exclusive Power-ups'),
            _buildPremiumFeature(Icons.palette, 'Premium Themes'),
            _buildPremiumFeature(Icons.emoji_events, 'Special Badge'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple,
                ),
                child: const Text(
                  '\$4.99/month',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cancel anytime',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}