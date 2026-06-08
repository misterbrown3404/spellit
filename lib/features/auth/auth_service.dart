import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/player_model.dart';

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
     // print('Auth state error in currentPlayerProvider: $e');
      return const Stream.empty();
    },
  );
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Email/Password Registration
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _ensureUserDocument(credential.user!, displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email/Password Sign In
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update daily streak and ensure document exists
      if (credential.user != null) {
        await _ensureUserDocument(credential.user!, credential.user!.displayName ?? 'Player');
        await _updateDailyStreak(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Anonymous Sign In (Guest mode)
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      
      if (credential.user != null) {
        await _ensureUserDocument(credential.user!, 'Guest_${credential.user!.uid.substring(0, 5)}');
      }

      return credential;
    } catch (e) {
      throw Exception('Failed to sign in as guest');
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _ensureUserDocument(
          userCredential.user!,
          googleUser.displayName ?? 'Player',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Ensure user document exists in Firestore
  Future<void> _ensureUserDocument(User user, String displayName) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final userDoc = _firestore.collection('users').doc(user.uid);
        // Try to get document with a timeout
        final docSnapshot = await userDoc.get().timeout(const Duration(seconds: 5));

      if (!docSnapshot.exists) {
        final newPlayer = PlayerModel(
          odid: user.uid,
          displayName: displayName,
          email: user.email ?? '',
          lastLoginDate: DateTime.now(),
          coins: 100,
          eloRating: 1000,
        );

        await userDoc.set(newPlayer.toFirestore());
        print('Created new user document for ${user.uid}');
      } else {
        // Ensure the document exists and update last login
        await userDoc.set({
          'lastLoginDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
          return; // Success, exit the loop
        }
      } on FirebaseException catch (e) {
        if (e.code == 'unavailable' && retryCount < maxRetries - 1) {
          retryCount++;
          print('Firestore unavailable, retrying ($retryCount/$maxRetries)...');
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
        print('Firestore Error: ${e.code} - ${e.message}');
        break;
      } catch (e) {
        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
        print('Error ensuring user document: $e');
        break;
      }
    }
  }

  // Update daily streak
  Future<void> _updateDailyStreak(String odid) async {
    try {
      final userDoc = _firestore.collection('users').doc(odid);
      final docSnapshot = await userDoc.get();

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
            // Consecutive day login
            currentStreak++;
            coinsToAdd = _getStreakBonus(currentStreak);
          } else if (difference > 1) {
            // Streak broken
            currentStreak = 1;
            coinsToAdd = 10; // Base daily login bonus
          } else if (difference == 0) {
            // Same day login, no bonus
            return;
          }
        } else {
          currentStreak = 1;
          coinsToAdd = 10;
        }

        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

        await userDoc.update({
          'lastLoginDate': Timestamp.fromDate(now),
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'coins': FieldValue.increment(coinsToAdd),
        });
      }
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        print('Firestore unavailable during streak update. Cached data will be synced later.');
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
      await _firestore.collection('users').doc(user.uid).delete();
      
      // 2. Delete Auth user
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('This action requires recent authentication. Please sign out and sign in again before deleting your account.');
      }
      throw _handleAuthException(e);
    } catch (e) {
     // print('Delete account error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
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
      default:
        return 'An error occurred. Please try again.';
    }
  }
  Future<void> updateDisplayName(String odid, String displayName) async {
  await _firestore.collection('users').doc(odid).update({
    'displayName': displayName,
  });
}
}