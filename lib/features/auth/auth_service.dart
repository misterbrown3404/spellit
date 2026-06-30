import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/player_model.dart';
import '../../core/achievement_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentPlayerProvider = StreamProvider<PlayerModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();

      // Use includeMetadataChanges: true to see if data is from cache
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(includeMetadataChanges: true)
          .map((doc) {
            return doc.exists ? PlayerModel.fromFirestore(doc) : null;
          });
    },
    loading: () => const Stream.empty(),
    error: (e, __) {
      debugPrint('Auth state error in currentPlayerProvider: $e');
      return const Stream.empty();
    },
  );
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Centralized timeouts so no auth-related call can hang the UI forever.
  static const _networkTimeout = Duration(seconds: 15);
  static const _fcmTimeout = Duration(seconds: 5);
  static const _firestoreTimeout = Duration(seconds: 5);

  User? get currentUser => _auth.currentUser;

  // Email/Password Registration
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_networkTimeout);

      if (credential.user != null) {
        await _ensureUserDocument(credential.user!, displayName);
        await _saveFCMToken(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } on TimeoutException {
      throw Exception('This is taking longer than expected. Please try again.');
    }
  }

  // Email/Password Sign In
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_networkTimeout);

      // Update daily streak and ensure document exists
      if (credential.user != null) {
        await _ensureUserDocument(
          credential.user!,
          credential.user!.displayName ?? 'Player',
        );
        await _updateDailyStreak(credential.user!.uid);
        await _saveFCMToken(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } on TimeoutException {
      throw Exception('This is taking longer than expected. Please try again.');
    }
  }

  // Anonymous Sign In (Guest mode)
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously().timeout(
        _networkTimeout,
      );

      if (credential.user != null) {
        await _ensureUserDocument(
          credential.user!,
          'Guest_${credential.user!.uid.substring(0, 5)}',
        );
        await _saveFCMToken(credential.user!.uid);
      }

      return credential;
    } on TimeoutException {
      throw Exception('This is taking longer than expected. Please try again.');
    } catch (e) {
      debugPrint('Guest sign-in error: $e');
      throw Exception('Failed to sign in as guest');
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      debugPrint('[Auth] 1/5 starting googleSignIn.signIn()');
      final GoogleSignInAccount? googleUser = await googleSignIn
          .signIn()
          .timeout(_networkTimeout);
      debugPrint('[Auth] 2/5 googleUser=${googleUser?.email}');

      if (googleUser == null) {
        // User cancelled the picker — not an error.
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication
          .timeout(_networkTimeout);
      debugPrint('[Auth] 3/5 got googleAuth tokens');

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(_networkTimeout);
      debugPrint('[Auth] 4/5 got userCredential');

      if (userCredential.user != null) {
        await _ensureUserDocument(
          userCredential.user!,
          googleUser.displayName ?? 'Player',
        );
        await _saveFCMToken(userCredential.user!.uid);
      }
      debugPrint('[Auth] 5/5 done');

      return userCredential;
    } on TimeoutException {
      throw Exception(
        'Sign-in is taking longer than expected. Check your connection and try again.',
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      debugPrint('[Auth] Google sign-in error: $e');
      throw Exception('Failed to sign in with Google. Please try again.');
    }
  }

  // Ensure user document exists in Firestore
  Future<void> _ensureUserDocument(User user, String displayName) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get().timeout(_firestoreTimeout);

        if (!docSnapshot.exists) {
          final newPlayer = PlayerModel(
            odid: user.uid,
            displayName: displayName,
            email: user.email ?? '',
            lastLoginDate: DateTime.now(),
          );
          await userDoc.set(newPlayer.toFirestore()).timeout(_firestoreTimeout);
          debugPrint('Created new user document for ${user.uid}');
          return;
        } else {
          await userDoc
              .set({
                'lastLoginDate': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(_firestoreTimeout);
          return; // Success, exit the loop
        }
      } on TimeoutException {
        retryCount++;
        debugPrint('Firestore timeout, retry $retryCount/$maxRetries');
        if (retryCount >= maxRetries) {
          debugPrint('Giving up on _ensureUserDocument after timeouts');
          break;
        }
        await Future.delayed(Duration(seconds: 2 * retryCount));
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable' && retryCount < maxRetries - 1) {
          retryCount++;
          debugPrint(
            'Firestore unavailable, retrying ($retryCount/$maxRetries)...',
          );
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
        debugPrint('Firestore Error: ${e.code} - ${e.message}');
        break;
      } catch (e) {
        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
        debugPrint('Error ensuring user document: $e');
        break;
      }
    }
  }

  Future<void> _saveFCMToken(String uid) async {
    try {
      // getToken() is known to hang indefinitely on iOS simulators / devices
      // without proper push entitlements — never await it unbounded.
      final token = await FirebaseMessaging.instance.getToken().timeout(
        _fcmTimeout,
      );
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .set({'fcmToken': token}, SetOptions(merge: true))
            .timeout(_firestoreTimeout);
      }
    } on TimeoutException {
      debugPrint('FCM token fetch/save timed out, skipping');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  // Update daily streak
  Future<void> _updateDailyStreak(String odid) async {
    try {
      final userDoc = _firestore.collection('users').doc(odid);
      final docSnapshot = await userDoc.get().timeout(_firestoreTimeout);

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final lastLogin = (data['lastLoginDate'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        int currentStreak = data['currentStreak'] ?? 0;
        int longestStreak = data['longestStreak'] ?? 0;
        int coinsToAdd = 0;

        if (lastLogin != null) {
          final difference = now.difference(lastLogin).inDays;

          if (difference == 1) {
            currentStreak++;
            coinsToAdd = _getStreakBonus(currentStreak);
          } else if (difference > 1) {
            currentStreak = 1;
            coinsToAdd = 10;
          } else if (difference == 0) {
            return;
          }
        } else {
          currentStreak = 1;
          coinsToAdd = 10;
        }

        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

        await userDoc
            .update({
              'lastLoginDate': Timestamp.fromDate(now),
              'currentStreak': currentStreak,
              'longestStreak': longestStreak,
              'coins': FieldValue.increment(coinsToAdd),
            })
            .timeout(_firestoreTimeout);

        if (currentStreak == 7 || currentStreak == 30) {
          await AchievementService().checkAndGrantAchievements(
            odid,
            PlayerModel(
              odid: odid,
              displayName: data['displayName'] ?? 'Player',
              email: data['email'] ?? '',
              currentStreak: currentStreak,
              longestStreak: longestStreak,
              lastLoginDate: now,
            ),
          );
        }
      }
    } on TimeoutException {
      debugPrint('Firestore timeout during streak update, skipping.');
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        debugPrint('Firestore unavailable during streak update.');
      } else {
        rethrow;
      }
    }
  }

  int _getStreakBonus(int streak) {
    // Increasing rewards for consecutive days
    if (streak >= 30) return 100;
    if (streak >= 14) return 75;
    if (streak >= 7) return 50;
    if (streak >= 3) return 30;
    return 15;
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Delete Firestore document first
      await _firestore
          .collection('users')
          .doc(user.uid)
          .delete()
          .timeout(_firestoreTimeout);

      // 2. Delete Auth user
      await user.delete().timeout(_networkTimeout);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'This action requires recent authentication. Please sign out and sign in again before deleting your account.',
        );
      }
      throw Exception(_handleAuthException(e));
    } on TimeoutException {
      throw Exception('This is taking longer than expected. Please try again.');
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email).timeout(_networkTimeout);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } on TimeoutException {
      throw Exception('This is taking longer than expected. Please try again.');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> updateDisplayName(String odid, String displayName) async {
    await _firestore
        .collection('users')
        .doc(odid)
        .update({'displayName': displayName})
        .timeout(_firestoreTimeout);
  }
}
