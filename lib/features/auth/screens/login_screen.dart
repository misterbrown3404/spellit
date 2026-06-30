import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spellit/features/auth/auth_service.dart';

// ── Main Screen ──────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(e);
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

  String _getFriendlyErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network-request-failed')) {
      return 'Please check your internet connection and try again.';
    } else if (errorStr.contains('too-many-requests')) {
      return 'Too many login attempts. Please try again later.';
    } else if (errorStr.contains('account-exists-with-different-credential')) {
      return 'An account already exists with a different sign-in method.';
    }
    return 'Could not complete sign in. Please verify your details.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // Pure white
              Color(0xFFF8F9FA), // Slightly off-white
              Color(0xFFF1F3F5),
            ],
          ),
        ),
        child: Stack(
          children: [
            const _FloatingLetters(),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const _MascotHeader(),
                    const SizedBox(height: 25),
                    const _DailyStreakCard(),
                    const SizedBox(height: 30),
                    //_StartAdventureButton(onPressed: _handleGoogleSignIn),
                    // const SizedBox(height: 20),
                    _GoogleSignInButton(
                      isLoading: _isLoading,
                      onPressed: _handleGoogleSignIn,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const _LegalText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating Letters Animation ────────────────────────────────────────────

class _FloatingLetters extends StatelessWidget {
  const _FloatingLetters();

  @override
  Widget build(BuildContext context) {
    final letters = ['S', 'P', 'E', 'L', 'L', 'I', 'T'];
    return Stack(
      children: letters.asMap().entries.map((entry) {
        final index = entry.key;
        final letter = entry.value;
        return Positioned(
          top: 50 + (index * 25) % 150,
          left: 20 + (index * 45) % (MediaQuery.of(context).size.width - 60),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(seconds: 3 + index),
            builder: (context, value, child) {
              return Opacity(
                opacity: 0.1 + (0.1 * value),
                child: Transform.translate(
                  offset: Offset(0, -20 * value),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 42,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

// ── Mascot Header ──────────────────────────────────────────────────────────

class _MascotHeader extends StatelessWidget {
  const _MascotHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 130,
          width: 130,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text("🦉", style: TextStyle(fontSize: 70)),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [Color(0xffFFD93D), Color(0xffFF6B6B), Color(0xff6C63FF)],
            ).createShader(bounds);
          },
          child: const Text(
            "SPELLIT",
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Become a Spelling Champion! 🏆",
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DailyStreakCard extends StatelessWidget {
  const _DailyStreakCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Daily Streak",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Spacer(),
              Text(
                "🔥 5 Days",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              7,
              (index) => Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: index < 5
                        ? Colors.amber.shade300
                        : Colors.grey.shade300,
                    child: Icon(
                      index < 5 ? Icons.star : Icons.star_border,
                      color: index < 5 ? Colors.white : Colors.grey.shade500,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${index + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      color: index < 5 ? Colors.amber.shade700 : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.shade200.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond, color: Color(0xff6C63FF)),
                SizedBox(width: 8),
                Text(
                  "Today's Reward: 50 Gems",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff4A3FFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google Sign In Button ─────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : const Color(0xff6C63FF),
                  ),
                ),
              )
            : Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/google.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata,
                      size: 20,
                      color: Color(0xff6C63FF),
                    ),
                  ),
                ),
              ),
        label: Text(
          isLoading ? 'Signing in...' : 'Continue with Google',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xff1A1A1A),
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff1A1A1A),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xffE8EAED), width: 1.5),
        ),
      ),
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legal Text ─────────────────────────────────────────────────────────────

class _LegalText extends StatelessWidget {
  const _LegalText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "By continuing you agree to our Terms of Service and Privacy Policy",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }
}
