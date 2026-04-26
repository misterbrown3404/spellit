// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:timezone/data/latest_all.dart' as tz_data;
// import 'package:timezone/timezone.dart' as tz;

// final notificationServiceProvider = Provider((ref) => NotificationService());

// class NotificationService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   static const String _dailyReminderId = 'daily_reminder_100';
//   static const String _gameRemindersChannelId = 'game_reminders';
//   static const String _gameRemindersChannelName = 'Game Reminders';
//   static const String _dailyReminderChannelId = 'daily_reminder';
//   static const String _dailyReminderChannelName = 'Daily Reminder';

//   bool _isInitialized = false;

//   Future<void> init() async {
//     if (_isInitialized) return;

//     try {
//       // Initialize timezone data for scheduling
//       _initializeTimezone();

//       // Request permissions
//       await _requestNotificationPermissions();

//       // Initialize Local Notifications
//       await _initializeLocalNotifications();

//       // Setup FCM message handlers
//       _setupFCMHandlers();

//       // Get and log FCM Token
//       await _getFCMToken();

//       // Schedule daily reminder
//       await scheduleDailyReminder();

//       _isInitialized = true;
//       print('✅ NotificationService initialized successfully');
//     } catch (e) {
//       print('❌ Error initializing NotificationService: $e');
//       rethrow;
//     }
//   }

//   void _initializeTimezone() {
//     try {
//       tz_data.initializeTimeZones();
//     } catch (e) {
//       print('⚠️ Error initializing timezone: $e');
//     }
//   }

//   Future<void> _requestNotificationPermissions() async {
//     try {
//       final settings = await _fcm.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false,
//       );

//       final status = settings.authorizationStatus;
//       if (status == AuthorizationStatus.authorized) {
//         print('✅ Notification permissions granted');
//       } else if (status == AuthorizationStatus.provisional) {
//         print('⚠️ Provisional notification permissions granted');
//       } else {
//         print('❌ Notification permissions denied');
//       }
//     } catch (e) {
//       print('❌ Error requesting notification permissions: $e');
//     }
//   }

//   Future<void> _initializeLocalNotifications() async {
//     try {
//       const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//       const iosSettings = DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );

//       const initSettings = InitializationSettings(
//         android: androidSettings,
//         iOS: iosSettings,
//       );

//       await _localNotifications.initialize(
//         initSettings,
//         onDidReceiveNotificationResponse: _handleNotificationTap,
//       );

//       // Create Android notification channels
//       await _createAndroidNotificationChannels();

//       print('✅ Local notifications initialized');
//     } catch (e) {
//       print('❌ Error initializing local notifications: $e');
//       rethrow;
//     }
//   }

//   Future<void> _createAndroidNotificationChannels() async {
//     try {
//       final androidPlugin = _localNotifications
//           .resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin>();

//       if (androidPlugin != null) {
//         // Game reminders channel
//         await androidPlugin.createNotificationChannel(
//           AndroidNotificationChannel(
//             id: _gameRemindersChannelId,
//             name: _gameRemindersChannelName,
//             description: 'Notifications to remind you to play',
//             importance: Importance.max,
//             enableVibration: true,
//           ),
//         );

//         // Daily reminder channel
//         await androidPlugin.createNotificationChannel(
//           AndroidNotificationChannel(
//             id: _dailyReminderChannelId,
//             name: _dailyReminderChannelName,
//             description: 'Reminds you to play every day',
//             importance: Importance.defaultImportance,
//             enableVibration: true,
//           ),
//         );
//       }
//     } catch (e) {
//       print('⚠️ Error creating notification channels: $e');
//     }
//   }

//   void _setupFCMHandlers() {
//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen(
//       (RemoteMessage message) {
//         print('📨 FCM message received in foreground: ${message.notification?.title}');
//         _showLocalNotification(
//           message.notification?.title ?? 'SpellIt',
//           message.notification?.body ?? '',
//         );
//       },
//       onError: (error) {
//         print('❌ Error listening to FCM messages: $error');
//       },
//     );

//     // Handle background/terminated message taps
//     FirebaseMessaging.onMessageOpenedApp.listen(
//       (RemoteMessage message) {
//         print('📨 FCM message tap: ${message.notification?.title}');
//         _handleNotificationTap(
//           NotificationResponse(
//             notificationResponseType: NotificationResponseType.selectedNotification,
//             payload: message.data['route'] ?? '',
//           ),
//         );
//       },
//       onError: (error) {
//         print('❌ Error listening to FCM opened app: $error');
//       },
//     );
//   }

//   void _handleNotificationTap(NotificationResponse response) {
//     // Handle notification tap - route to appropriate screen
//     final payload = response.payload;
//     if (payload != null && payload.isNotEmpty) {
//       print('🎯 Navigating to route: $payload');
//       // You can implement route navigation here using your router
//       // Example: GoRouter.of(context).push(payload);
//     }
//   }

//   Future<void> _getFCMToken() async {
//     try {
//       final token = await _fcm.getToken();
//       if (token != null) {
//         print('🔑 FCM Token: $token');
//       } else {
//         print('⚠️ FCM Token is null');
//       }
//     } catch (e) {
//       print('❌ Error getting FCM token: $e');
//     }
//   }

//   Future<void> saveTokenToFirestore(String userId) async {
//     try {
//       final token = await _fcm.getToken();
//       if (token != null && userId.isNotEmpty) {
//         await FirebaseFirestore.instance.collection('users').doc(userId).update({
//           'fcmToken': token,
//           'lastActive': FieldValue.serverTimestamp(),
//           'notificationsEnabled': true,
//         });
//         print('✅ FCM token saved to Firestore for user: $userId');
//       } else {
//         print('⚠️ Cannot save FCM token: token=$token, userId=$userId');
//       }
//     } catch (e) {
//       print('❌ Error saving FCM token to Firestore: $e');
//     }
//   }

//   Future<void> _showLocalNotification(String title, String body) async {
//     try {
//       const androidDetails = AndroidNotificationDetails(
//         _gameRemindersChannelId,
//         _gameRemindersChannelName,
//         channelDescription: 'Notifications to remind you to play',
//         importance: Importance.max,
//         priority: Priority.high,
//         enableVibration: true,
//       );
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       );

//       await _localNotifications.show(
//         title.hashCode,
//         title,
//         body,
//         NotificationDetails(
//           android: androidDetails,
//           iOS: iosDetails,
//         ),
//       );
//       print('✅ Local notification shown: $title');
//     } catch (e) {
//       print('❌ Error showing local notification: $e');
//     }
//   }

//   Future<void> scheduleDailyReminder({int hour = 18, int minute = 0}) async {
//     try {
//       // Cancel existing reminders to avoid duplicates
//       await _localNotifications.cancel(100);

//       final now = tz.TZDateTime.now(tz.local);
//       var scheduledDate = tz.TZDateTime(
//         tz.local,
//         now.year,
//         now.month,
//         now.day,
//         hour,
//         minute,
//       );

//       // If the time has already passed today, schedule for tomorrow
//       if (scheduledDate.isBefore(now)) {
//         scheduledDate = scheduledDate.add(const Duration(days: 1));
//       }

//       const androidDetails = AndroidNotificationDetails(
//         _dailyReminderChannelId,
//         _dailyReminderChannelName,
//         channelDescription: 'Reminds you to play every day',
//         importance: Importance.defaultImportance,
//         enableVibration: true,
//       );
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       );

//       await _localNotifications.zonedSchedule(
//         100,
//         'Time for a Word Battle! 🎮',
//         'Your daily streak is waiting. Come and challenge your friends in SpellIt!',
//         scheduledDate,
//         NotificationDetails(
//           android: androidDetails,
//           iOS: iosModeDetails(iosDetails),
//         ),
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//         matchDateTimeComponents: DateTimeComponents.time,
//       );

//       print('✅ Daily reminder scheduled for ${scheduledDate.hour}:${scheduledDate.minute}');
//     } catch (e) {
//       print('❌ Error scheduling daily reminder: $e');
//     }
//   }

//   // Helper for cross-platform compatibility
//   NotificationDetails iosModeDetails(DarwinNotificationDetails iosDetails) {
//     return NotificationDetails(
//       iOS: iosDetails,
//     );
//   }

//   // Method to cancel daily reminder
//   Future<void> cancelDailyReminder() async {
//     try {
//       await _localNotifications.cancel(100);
//       print('✅ Daily reminder cancelled');
//     } catch (e) {
//       print('❌ Error cancelling daily reminder: $e');
//     }
//   }

//   // Method to disable/enable notifications
//   Future<void> setNotificationsEnabled(String userId, bool enabled) async {
//     try {
//       if (enabled) {
//         await scheduleDailyReminder();
//       } else {
//         await cancelDailyReminder();
//       }

//       await FirebaseFirestore.instance.collection('users').doc(userId).update({
//         'notificationsEnabled': enabled,
//       });

//       print(
//           '✅ Notifications ${enabled ? 'enabled' : 'disabled'} for user: $userId');
//     } catch (e) {
//       print('❌ Error setting notification preference: $e');
//     }
//   }

//   // Clean dispose
//   void dispose() {
//     _isInitialized = false;
//   }
// }