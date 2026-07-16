import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/player_model.dart';
import '../../core/achievement_service.dart';
import '../../core/di/firebase_providers.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network_utils.dart';
import 'package:spellit/features/leaderboard/leaderboard_service.dart';

final authServiceProvider = Provider((ref) {
  return AuthService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
    messaging: ref.watch(firebaseMessagingProvider),
    leaderboard: ref.watch(leaderboardServiceProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentPlayerProvider = StreamProvider<PlayerModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();

      // Use includeMetadataChanges: true to see if data is from cache
      return ref
          .watch(firebaseFirestoreProvider)
          .collection('users')
          .doc(user.uid)
          .snapshots(includeMetadataChanges: true)
          .map((doc) {
            return doc.exists ? PlayerModel.fromFirestore(doc) : null;
          });
    },
    loading: () => const Stream.empty(),
    error: (e, __) {
      AppLogger.error(e, operation: 'currentPlayerProvider');
      return const Stream.empty();
    },
  );
});

class AuthService {
  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
    required LeaderboardService leaderboard,
  })  : _auth = auth,
        _firestore = firestore,
        _messaging = messaging,
        _leaderboard = leaderboard;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final LeaderboardService _leaderboard;

  // Centralized timeouts so no auth-related call can hang the UI forever.
  static const _networkTimeout = Duration(seconds: 15);
  static const _fcmTimeout = Duration(seconds: 5);
  static const _firestoreTimeout = Duration(seconds: 5);

  User? get currentUser => _auth.currentUser;

  /// Ensure the signed-in user has a leaderboard entry. Best-effort: reads the
  /// user doc (owner-only read is fine) and upserts the denormalized public
  /// leaderboard entry. Failures are logged, never surfaced to the UI.
  Future<void> syncLeaderboardForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(_firestoreTimeout);
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      await _leaderboard.syncEntry(
        userId: user.uid,
        displayName: data['displayName'] as String? ?? 'Player',
        eloRating: data['eloRating'] as int? ?? 1000,
        totalWins: data['totalWins'] as int? ?? 0,
        longestStreak: data['longestStreak'] as int? ?? 0,
        avatarUrl: data['avatarUrl'] as String? ?? '',
      );
    } catch (e) {
      AppLogger.error(e, operation: 'Sync leaderboard for current user');
    }
  }

  // Email/Password Registration
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await AppNetwork.execute(
        operationName: 'registerWithEmail',
        action: () => _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
        timeout: _networkTimeout,
      );

      if (credential.user != null) {
        await _ensureUserDocument(credential.user!, displayName);
        await _saveFCMToken(credential.user!.uid);
        await _syncLeaderboardEntry(credential.user!, displayName);
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
      final credential = await AppNetwork.execute(
        operationName: 'signInWithEmail',
        action: () => _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
        timeout: _networkTimeout,
      );

      // Update daily streak and ensure document exists
      if (credential.user != null) {
        await _ensureUserDocument(
          credential.user!,
          credential.user!.displayName ?? 'Player',
        );
        await _updateDailyStreak(credential.user!.uid);
        await _saveFCMToken(credential.user!.uid);
        await _syncLeaderboardEntry(
          credential.user!,
          credential.user!.displayName ?? 'Player',
        );
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
      final credential = await AppNetwork.execute(
        operationName: 'signInAnonymously',
        action: () => _auth.signInAnonymously(),
        timeout: _networkTimeout,
      );

      if (credential.user != null) {
        await _ensureUserDocument(
          credential.user!,
          'Guest_${credential.user!.uid.substring(0, 5)}',
        );
        await _saveFCMToken(credential.user!.uid);
        await _syncLeaderboardEntry(
          credential.user!,
          'Guest_${credential.user!.uid.substring(0, 5)}',
        );
      }

      return credential;
    } on TimeoutException {
      throw Exception('This is taking longer than expected. Please try again.');
    } catch (e) {
      AppLogger.error(e, operation: 'Guest sign-in');
      throw Exception('Failed to sign in as guest');
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      AppLogger.info('[Auth] starting Google sign-in');
      final GoogleSignInAccount? googleUser = await AppNetwork.execute(
        operationName: 'googleSignIn',
        action: () => googleSignIn.signIn(),
        timeout: _networkTimeout,
      );
      AppLogger.info(
        '[Auth] Google account selected',
        context: {'email': googleUser?.email ?? 'null'},
      );

      if (googleUser == null) {
        // User cancelled the picker — not an error.
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await AppNetwork.execute(
        operationName: 'googleAuth',
        action: () => googleUser.authentication,
        timeout: _networkTimeout,
      );
      AppLogger.info('[Auth] Google auth tokens received');

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await AppNetwork.execute(
        operationName: 'signInWithCredential',
        action: () => _auth.signInWithCredential(credential),
        timeout: _networkTimeout,
      );
      AppLogger.info('[Auth] Firebase credential accepted');

      if (userCredential.user != null) {
        await _ensureUserDocument(
          userCredential.user!,
          googleUser.displayName ?? 'Player',
        );
        await _saveFCMToken(userCredential.user!.uid);
        await _syncLeaderboardEntry(
          userCredential.user!,
          googleUser.displayName ?? 'Player',
        );
      }
      AppLogger.info('[Auth] Google sign-in complete');

      return userCredential;
    } on TimeoutException {
      throw Exception(
        'Sign-in is taking longer than expected. Check your connection and try again.',
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      AppLogger.error(e, operation: 'Google sign-in');
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
          AppLogger.info('Created user document');
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
        AppLogger.warning(
          'Firestore timeout while ensuring user document',
          context: {'retry': retryCount, 'maxRetries': maxRetries},
        );
        if (retryCount >= maxRetries) {
          AppLogger.warning('Giving up on user document creation after timeouts');
          break;
        }
        await Future.delayed(Duration(seconds: 2 * retryCount));
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable' && retryCount < maxRetries - 1) {
          retryCount++;
          AppLogger.warning(
            'Firestore unavailable, retrying ($retryCount/$maxRetries)...',
          );
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
        AppLogger.error(e, operation: 'Ensure user document');
        break;
      } catch (e) {
        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
        AppLogger.error(e, operation: 'Ensure user document');
        break;
      }
    }
  }

  Future<void> _syncLeaderboardEntry(User user, String displayName) async {
    // Keep the denormalized public leaderboard current. Best-effort: failures
    // must not block sign-in. Reads are safe (owner-only on users) and the
    // service truncates under timeouts.
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(_firestoreTimeout);
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      await _leaderboard.syncEntry(
        userId: user.uid,
        displayName: displayName,
        eloRating: data['eloRating'] as int? ?? 1000,
        totalWins: data['totalWins'] as int? ?? 0,
        longestStreak: data['longestStreak'] as int? ?? 0,
        avatarUrl: data['avatarUrl'] as String? ?? '',
      );
    } catch (e) {
      AppLogger.error(e, operation: 'Sync leaderboard on auth');
    }
  }

  Future<void> _saveFCMToken(String uid) async {
    try {
      // getToken() is known to hang indefinitely on iOS simulators / devices
      // without proper push entitlements — never await it unbounded.
      final token = await AppNetwork.execute(
        operationName: 'saveFCMToken',
        action: () => _messaging.getToken(),
        timeout: _fcmTimeout,
      );
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .set({'fcmToken': token}, SetOptions(merge: true))
            .timeout(_firestoreTimeout);
      }
    } on TimeoutException {
      AppLogger.warning('FCM token fetch/save timed out, skipping');
    } catch (e) {
      AppLogger.error(e, operation: 'Save FCM token');
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
      AppLogger.warning('Firestore timeout during streak update, skipping.');
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        AppLogger.warning('Firestore unavailable during streak update.');
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
      // 1. Delete Firestore user document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .delete()
          .timeout(_firestoreTimeout);

      // 2. Delete leaderboard entry so deleted user doesn't remain on the board
      await _firestore
          .collection('leaderboard')
          .doc(user.uid)
          .delete()
          .timeout(_firestoreTimeout);

      // 3. Clear Google session if applicable
      await GoogleSignIn().signOut();

      // 4. Delete Auth user
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
      AppLogger.error(e, operation: 'Delete account');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await AppNetwork.execute(
        operationName: 'sendPasswordResetEmail',
        action: () => _auth.sendPasswordResetEmail(email: email),
        timeout: _networkTimeout,
      );
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
