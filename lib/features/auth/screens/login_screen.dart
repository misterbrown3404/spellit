import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).signInAnonymously();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                _buildLogo().animate().fadeIn(duration: 800.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ),

                const SizedBox(height: 20),

                Text(
                  'SPELLIT',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: colorScheme.onSurface,
                        fontSize: 48,
                      ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 8),

                Text(
                  'Master the art of words',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 600.ms),

                const SizedBox(height: 48),

                _buildFeatureCards(colorScheme).animate().fadeIn(delay: 450.ms, duration: 700.ms).slideY(
                  begin: 0.2,
                  curve: Curves.easeOutCubic,
                ),

                const SizedBox(height: 40),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.error.withOpacity(0.5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildGoogleButton(colorScheme).animate().fadeIn(delay: 550.ms, duration: 600.ms),

                const SizedBox(height: 14),

                _buildGuestButton(colorScheme).animate().fadeIn(delay: 650.ms, duration: 600.ms),

                const SizedBox(height: 32),

                Text(
                  'By continuing, you agree to our Terms of Service',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.grid_view_rounded,
        size: 52,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFeatureCards(ColorScheme colorScheme) {
    final features = [
      _FeatureItem(
        icon: Icons.person_rounded,
        title: 'Solo Play',
        subtitle: 'Practice & climb ranks',
      ),
      _FeatureItem(
        icon: Icons.people_rounded,
        title: 'Multiplayer',
        subtitle: 'Battle with friends',
      ),
      _FeatureItem(
        icon: Icons.card_giftcard_rounded,
        title: 'Daily Rewards',
        subtitle: 'Claim streak bonuses',
      ),
    ];

    return Row(
      children: features.map((feature) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  feature.icon,
                  size: 28,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  feature.title,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoogleButton(ColorScheme colorScheme) {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icons/google.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
      label: const Text(
        'Continue with Google',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.15),
      ),
    );
  }

  Widget _buildGuestButton(ColorScheme colorScheme) {
    return TextButton(
      onPressed: _isLoading ? null : _playAsGuest,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
        ),
      ),
      child: const Text(
        'Continue as Guest',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
