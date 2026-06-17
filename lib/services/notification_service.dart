import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    // FCM initialization would go here in production
    _isInitialized = true;
  }

  Future<void> showNotification(String title, String body) async {
    debugPrint('Notification: $title - $body');
  }

  Future<void> scheduleReminder(int hour, int minute) async {
    debugPrint('Reminder scheduled for $hour:$minute');
  }
}
