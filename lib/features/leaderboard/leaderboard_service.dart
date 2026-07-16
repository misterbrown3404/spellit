import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/firebase_providers.dart';
import '../../core/logging/app_logger.dart';

final leaderboardServiceProvider = Provider((ref) {
  return LeaderboardService(firestore: ref.watch(firebaseFirestoreProvider));
});

/// Combined stream for a leaderboard screen: the top N entries plus the
/// current signed-in user (deduped) in a single subscription.
final leaderboardWithUserProvider = StreamProvider.autoDispose
    .family<LeaderboardViewData, String?>((ref, userId) {
      final service = ref.watch(leaderboardServiceProvider);
      return service.watchTopWithUser(
        orderByField: 'eloRating',
        currentUserId: userId,
        limit: 10,
      );
    });

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.value,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final int value;
  final String? avatarUrl;
}

/// Result of a combined top-N + current-user leaderboard fetch.
///
/// [hasTopError] / [hasUserError] are set when a Firestore read fails or
/// times out. They never surface as a broken/errored StreamBuilder — the
/// screen just shows whatever data is available (possibly empty) plus an
/// optional small "couldn't refresh" indicator, instead of hanging or
/// throwing behind the scenes.
class LeaderboardViewData {
  const LeaderboardViewData({
    required this.topEntries,
    required this.currentUserEntry,
    required this.currentUserInTop,
    this.hasTopError = false,
    this.hasUserError = false,
  });

  final List<LeaderboardEntry> topEntries;
  final LeaderboardEntry? currentUserEntry;
  final bool currentUserInTop;
  final bool hasTopError;
  final bool hasUserError;

  bool get hasAnyError => hasTopError || hasUserError;

  LeaderboardViewData copyWith({
    List<LeaderboardEntry>? topEntries,
    LeaderboardEntry? Function()? currentUserEntry,
    bool? currentUserInTop,
    bool? hasTopError,
    bool? hasUserError,
  }) {
    return LeaderboardViewData(
      topEntries: topEntries ?? this.topEntries,
      currentUserEntry: currentUserEntry != null
          ? currentUserEntry()
          : this.currentUserEntry,
      currentUserInTop: currentUserInTop ?? this.currentUserInTop,
      hasTopError: hasTopError ?? this.hasTopError,
      hasUserError: hasUserError ?? this.hasUserError,
    );
  }
}

/// A denormalized, publicly-readable collection that backs the leaderboard.
///
/// `users/{userId}` read is restricted to the owner (PII), so a public
/// leaderboard must live in its own collection with only ranking fields and
/// public read access. Entries are kept in sync via [syncEntry], called after
/// login and after every game.
int? calculateLeaderboardRank(List<LeaderboardEntry> entries, String? userId) {
  if (userId == null) return null;

  final index = entries.indexWhere((entry) => entry.userId == userId);
  return index == -1 ? null : index + 1;
}

class LeaderboardService {
  LeaderboardService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const _readyFallback = Duration(seconds: 8);

  LeaderboardEntry _fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String orderByField,
  ) {
    final data = doc.data() ?? const {};
    return LeaderboardEntry(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? 'Player',
      value: (data[orderByField] as num?)?.toInt() ?? 0,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  /// Upsert the current user's entry. Safe for any signed-in user to call; the
  /// Firestore rule allows writes only to the caller's own document.
  Future<void> syncEntry({
    required String userId,
    required String displayName,
    required int eloRating,
    required int totalWins,
    required int longestStreak,
    String avatarUrl = '',
  }) async {
    try {
      await _firestore.collection('leaderboard').doc(userId).set({
        'displayName': displayName,
        'eloRating': eloRating,
        'totalWins': totalWins,
        'longestStreak': longestStreak,
        'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error(e, operation: 'Sync leaderboard entry');
    }
  }

  Stream<List<LeaderboardEntry>> watchRanked({
    required String orderByField,
    required DateTime? cutoff,
    int limit = 100,
  }) {
    var query = _firestore
        .collection('leaderboard')
        .orderBy(orderByField, descending: true)
        .limit(limit);

    // Firestore requires the equality/range filter field to be the (first)
    // orderBy field, so time-windowed queries order by `updatedAt` and are
    // re-sorted client-side by the requested metric.
    if (cutoff != null) {
      query = query.where(
        'updatedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
      );
    }

    return query.snapshots().map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => _fromDoc(doc, orderByField))
          .toList(growable: false);

      if (cutoff != null) {
        final sorted = [...entries]..sort((a, b) => b.value.compareTo(a.value));
        return sorted;
      }
      return entries;
    });
  }

  Future<LeaderboardEntry?> getEntry(String userId) async {
    try {
      final doc = await _firestore.collection('leaderboard').doc(userId).get();
      if (!doc.exists) return null;
      return _fromDoc(doc, 'eloRating');
    } catch (e) {
      AppLogger.error(e, operation: 'Get leaderboard entry');
      return null;
    }
  }

  /// Streams the top [limit] entries and the current user's entry together,
  /// as a single coordinated state, instead of two independent
  /// subscriptions that can race or double-listen on the same query.
  ///
  /// - Firestore errors on either subscription are logged and reflected as
  ///   [LeaderboardViewData.hasTopError] / [hasUserError] flags — they never
  ///   propagate as a stream error, so the UI never silently blanks out.
  /// - If neither subscription has produced its first snapshot within
  ///   [_readyFallback], the stream emits anyway with whatever is available
  ///   (typically empty) and the relevant error flag set, so the screen never
  ///   spins forever on a slow/offline connection.
  Stream<LeaderboardViewData> watchTopWithUser({
    required String orderByField,
    required String? currentUserId,
    int limit = 10,
  }) {
    late final StreamController<LeaderboardViewData> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? topSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;
    Timer? topFallback;
    Timer? userFallback;

    var topEntries = <LeaderboardEntry>[];
    LeaderboardEntry? userEntry;
    var topReady = false;
    var userReady = currentUserId == null;
    var topError = false;
    var userError = false;

    void emit() {
      if (!topReady || !userReady) return;
      if (controller.isClosed) return;
      final inTop = currentUserId == null
          ? false
          : topEntries.any((e) => e.userId == currentUserId);
      controller.add(
        LeaderboardViewData(
          topEntries: topEntries,
          currentUserEntry: userEntry,
          currentUserInTop: inTop,
          hasTopError: topError,
          hasUserError: userError,
        ),
      );
    }

    controller = StreamController<LeaderboardViewData>.broadcast(
      onListen: () {
        topFallback = Timer(_readyFallback, () {
          if (!topReady) {
            topReady = true;
            topError = true;
            emit();
          }
        });

        topSub = _firestore
            .collection('leaderboard')
            .orderBy(orderByField, descending: true)
            .limit(limit)
            .snapshots()
            .listen(
              (snapshot) {
                topEntries = snapshot.docs
                    .map((doc) => _fromDoc(doc, orderByField))
                    .toList(growable: false);
                topReady = true;
                topError = false;
                topFallback?.cancel();
                emit();
              },
              onError: (Object e, StackTrace st) {
                AppLogger.error(e, operation: 'Watch top leaderboard');
                topReady = true;
                topError = true;
                topFallback?.cancel();
                emit();
              },
            );

        if (currentUserId != null) {
          userFallback = Timer(_readyFallback, () {
            if (!userReady) {
              userReady = true;
              userError = true;
              emit();
            }
          });

          userSub = _firestore
              .collection('leaderboard')
              .doc(currentUserId)
              .snapshots()
              .listen(
                (doc) {
                  userEntry = doc.exists ? _fromDoc(doc, orderByField) : null;
                  userReady = true;
                  userError = false;
                  userFallback?.cancel();
                  emit();
                },
                onError: (Object e, StackTrace st) {
                  AppLogger.error(e, operation: 'Watch current user entry');
                  userReady = true;
                  userError = true;
                  userFallback?.cancel();
                  emit();
                },
              );
        }
      },
      onCancel: () async {
        topFallback?.cancel();
        userFallback?.cancel();
        await topSub?.cancel();
        await userSub?.cancel();
      },
    );

    return controller.stream;
  }
}
