import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/power_up_model.dart';

class PowerUpBar extends StatelessWidget {
  final Map<String, int> inventory; // { 'freeze': 2, 'reveal': 1 }
  final Function(PowerUpType) onPowerUpTap;
  final bool isEnabled;
  final Set<PowerUpType>? cooldowns; // Power-ups currently on cooldown

  const PowerUpBar({
    super.key,
    required this.inventory,
    required this.onPowerUpTap,
    this.isEnabled = true,
    this.cooldowns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPowerUpButton(
            context: context,
            type: PowerUpType.freeze,
            icon: Icons.ac_unit,
            color: Colors.lightBlue,
            count: inventory['freeze'] ?? 0,
          ),
          _buildPowerUpButton(
            context: context,
            type: PowerUpType.reveal,
            icon: Icons.lightbulb,
            color: Colors.amber,
            count: inventory['reveal'] ?? 0,
          ),
          _buildPowerUpButton(
            context: context,
            type: PowerUpType.shuffle,
            icon: Icons.shuffle,
            color: Colors.green,
            count: inventory['shuffle'] ?? 0,
          ),
          _buildPowerUpButton(
            context: context,
            type: PowerUpType.doublePoints,
            icon: Icons.double_arrow,
            color: Colors.purple,
            count: inventory['double_points'] ?? 0,
          ),
          _buildPowerUpButton(
            context: context,
            type: PowerUpType.bomb,
            icon: Icons.flash_on,
            color: Colors.red,
            count: inventory['bomb'] ?? 0,
          ),
          _buildPowerUpButton(
            context: context,
            type: PowerUpType.shield,
            icon: Icons.shield, 
            color: Colors.blueGrey, 
            count: inventory['shield'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildPowerUpButton({
    required BuildContext context,
    required PowerUpType type,
    required IconData icon,
    required Color color,
    required int count,
  }) {
    final isOnCooldown = cooldowns?.contains(type) ?? false;
    final hasItem = count > 0;
    final canUse = isEnabled && hasItem && !isOnCooldown;

    return GestureDetector(
      onTap: canUse ? () => onPowerUpTap(type) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: canUse
              ? color.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canUse ? color : Colors.grey,
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: canUse ? color : Colors.grey,
              size: 28,
            ),
            
            // Count badge
            if (count > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            // Cooldown overlay
            if (isOnCooldown)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ).animate(target: canUse ? 0 : 1).saturate(end: 0),
    );
  }
}
