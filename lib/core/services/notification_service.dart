// ============================================================
// NOTIFICATION SERVICE — GetWork App
// Handles Firebase Cloud Messaging (FCM), Local Notifications,
// FCM Token management, foreground banners, and deep linking.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../router.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('🔔 [FCM Background] Handling message ID: ${message.messageId}');
    print('🔔 [FCM Background] Data: ${message.data}');
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// High importance notification channel for Android foreground alerts
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'getwork_high_importance_channel', // id
    'GetWork Notifications', // title
    description: 'High importance notifications for GetWork jobs and updates.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize FCM + Local Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request permission from user (Android 13+ & iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}');
      }

      // 2. Setup Local Notifications for Foreground display
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _handleNotificationPayload(payload);
          }
        },
      );

      // Create Android Notification Channel
      final androidPlatform = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(_androidChannel);
      }

      // Set foreground presentation options for iOS/macOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Fetch & Print FCM Token
      await _fetchFcmToken();

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('🔑 [FCM Token Refreshed]: $newToken');
        }
        // TODO: Send updated token to Supabase / Backend database
      });

      // 4. Handle Foreground Messages (app active)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('🔔 [FCM Foreground] Received message: ${message.notification?.title}');
          print('🔔 [FCM Foreground] Data payload: ${message.data}');
        }

        final notification = message.notification;
        final android = message.notification?.android;

        // Show local notification banner if message contains a notification object
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannel.id,
                _androidChannel.name,
                channelDescription: _androidChannel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: message.data['jobId'] ?? message.data['type'] ?? '',
          );
        }
      });

      // 5. Handle Background Tap (app was in background, user tapped notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('🔔 [FCM App Opened from Background] Data: ${message.data}');
        }
        _handleMessageNavigation(message);
      });

      // 6. Handle Terminated Tap (app was closed, launched via notification tap)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('🔔 [FCM App Launched from Terminated] Data: ${initialMessage.data}');
        }
        // Delay slightly to allow router to initialize
        Future.delayed(const Duration(milliseconds: 600), () {
          _handleMessageNavigation(initialMessage);
        });
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ [NotificationService] Initialization complete!');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('⚠️ [NotificationService Error]: $e\n$stack');
      }
    }
  }

  /// Get current device FCM token
  Future<String?> _fetchFcmToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      if (kDebugMode) {
        print('==================================================');
        print('🔑 [FCM DEVICE TOKEN]:');
        print(_fcmToken);
        print('==================================================');
      }
      return _fcmToken;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FCM Token Error]: $e');
      }
      return null;
    }
  }

  /// Deep link navigation when user taps a notification
  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final jobId = data['jobId'] as String?;
    final type = data['type'] as String?;

    if (jobId != null && jobId.isNotEmpty) {
      appRouter.go('/job/$jobId');
    } else if (type == 'new_job') {
      appRouter.go(AppRoutes.home);
    } else if (type == 'notifications') {
      appRouter.go(AppRoutes.notifications);
    } else {
      appRouter.go(AppRoutes.notifications);
    }
  }

  /// Route payload string from local notification tap
  void _handleNotificationPayload(String payload) {
    if (payload.startsWith('job_') || payload.length > 5) {
      appRouter.go('/job/$payload');
    } else {
      appRouter.go(AppRoutes.notifications);
    }
  }
}
