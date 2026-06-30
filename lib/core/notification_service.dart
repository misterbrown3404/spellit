import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const _permissionTimeout = Duration(seconds: 5);
  static const _apnsTokenTimeout = Duration(seconds: 5);
  static const _fcmTokenTimeout = Duration(seconds: 5);

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
      debugPrint('Notification permission request failed: $e');
    }

    try {
      final apnsToken = await _messaging
          .getAPNSToken()
          .timeout(_apnsTokenTimeout);
      if (apnsToken != null) {
        debugPrint('APNS token received');
      }
    } catch (e) {
      debugPrint('APNS token fetch failed: $e');
    }

    final completer = Completer<String?>();
    late StreamSubscription<String?> tokenSub;
    tokenSub = _messaging.onTokenRefresh.listen((token) {
      if (!completer.isCompleted) completer.complete(token);
    });

    String? fcmToken;
    try {
      fcmToken = await _messaging
          .getToken()
          .timeout(_fcmTokenTimeout);
    } catch (e) {
      debugPrint('FCM token fetch failed: $e');
    }

    tokenSub.cancel();
    if (fcmToken != null) {
      debugPrint('FCM Token: $fcmToken');
    }
    if (!completer.isCompleted) completer.complete(fcmToken);

    FirebaseMessaging.onMessage.listen(_onMessageReceived);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);
  }

  static Future<void> _onMessageReceived(RemoteMessage message) async {
    debugPrint('Notification received: ${message.notification?.title}');
  }

  static Future<void> _onNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.notification?.title}');
  }

  Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await _messaging.getToken().timeout(_fcmTokenTimeout);
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> sendGameStartNotification(String userId, String roomCode) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'game_start',
        'title': 'Game Started!',
        'body': 'Room $roomCode is now live. Jump in!',
        'roomCode': roomCode,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Error sending game start notification: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }

  Future<void> sendFriendInviteNotification(String userId, String inviterName) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'friend_invite',
        'title': 'Game Invitation',
        'body': '$inviterName invited you to play!',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Error sending friend invite notification: $e');
    }
  }

  Future<void> clearNotifications(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
