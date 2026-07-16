import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'di/firebase_providers.dart';
import 'logging/app_logger.dart';
import 'network_utils.dart';

final notificationServiceProvider = Provider((ref) {
  return NotificationService(
    messaging: ref.watch(firebaseMessagingProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
  })  : _messaging = messaging,
        _firestore = firestore;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  static const _permissionTimeout = Duration(seconds: 5);
  static const _apnsTokenTimeout = Duration(seconds: 5);
  static const _fcmTokenTimeout = Duration(seconds: 5);
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  Future<void> init() async {
    try {
      await _messaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(_permissionTimeout);
    } catch (e) {
      AppLogger.error(e, operation: 'Notification permission request');
    }

    try {
      final apnsToken = await AppNetwork.execute(
        operationName: 'apnsToken',
        action: () => _messaging.getAPNSToken(),
        timeout: _apnsTokenTimeout,
      );
      if (apnsToken != null) {
        AppLogger.info('APNS token received');
      }
    } catch (e) {
      AppLogger.error(e, operation: 'APNS token fetch');
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      AppLogger.info(
        'FCM token refreshed',
        context: {'hasToken': token.isNotEmpty},
      );
    });

    String? fcmToken;
    try {
      fcmToken = await AppNetwork.execute(
        operationName: 'fcmToken',
        action: () => _messaging.getToken(),
        timeout: _fcmTokenTimeout,
      );
    } catch (e) {
      AppLogger.error(e, operation: 'FCM token fetch');
    }

    if (fcmToken != null) {
      AppLogger.info('FCM token fetched', context: {'hasToken': true});
    }

    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _onMessageReceived,
    );
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _onNotificationTap,
    );
  }

  static Future<void> _onMessageReceived(RemoteMessage message) async {
    AppLogger.info(
      'Notification received',
      context: {'messageId': message.messageId},
    );
  }

  static Future<void> _onNotificationTap(RemoteMessage message) async {
    AppLogger.info(
      'Notification tapped',
      context: {'messageId': message.messageId},
    );
  }

  Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await AppNetwork.execute(
        operationName: 'saveTokenToFirestore',
        action: () => _messaging.getToken(),
        timeout: _fcmTokenTimeout,
      );
      if (token != null) {
        await AppNetwork.execute<void>(
          operationName: 'saveNotificationToken',
          action: () => _firestore
              .collection('users')
              .doc(userId)
              .update({'fcmToken': token}),
        );
      }
    } catch (e) {
      AppLogger.error(e, operation: 'Save notification token');
    }
  }

  Future<void> sendGameStartNotification(String userId, String roomCode) async {
    try {
      await AppNetwork.execute<void>(
        operationName: 'sendGameStartNotification',
        action: () async {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'type': 'game_start',
            'title': 'Game Started!',
            'body': 'Room $roomCode is now live. Jump in!',
            'roomCode': roomCode,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        },
      );
    } catch (e) {
      AppLogger.error(e, operation: 'Send game start notification');
    }
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await AppNetwork.execute<void>(
      operationName: 'markNotificationAsRead',
      action: () => _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true}),
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await AppNetwork.execute<QuerySnapshot>(
      operationName: 'loadUnreadNotifications',
      action: () => _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .limit(100)
          .get(),
    );

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await AppNetwork.execute<void>(
      operationName: 'markAllNotificationsAsRead',
      action: batch.commit,
    );
  }

  Future<void> sendFriendInviteNotification(
    String userId,
    String inviterName,
  ) async {
    try {
      await AppNetwork.execute<void>(
        operationName: 'sendFriendInviteNotification',
        action: () async {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'type': 'friend_invite',
            'title': 'Game Invitation',
            'body': '$inviterName invited you to play!',
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        },
      );
    } catch (e) {
      AppLogger.error(e, operation: 'Send friend invite notification');
    }
  }

  Future<void> clearNotifications(String userId) async {
    final snapshot = await AppNetwork.execute<QuerySnapshot>(
      operationName: 'loadReadNotifications',
      action: () => _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: true)
          .limit(100)
          .get(),
    );

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await AppNetwork.execute<void>(
      operationName: 'clearNotifications',
      action: batch.commit,
    );
  }
}
