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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/notifications/models/notification_item.dart';
import '../../features/notifications/services/notification_repository.dart';
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
      await _fetchAndSaveFcmToken();

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('🔑 [FCM Token Refreshed]: $newToken');
        }
        await _saveFcmTokenToSupabase(newToken);
      });

      // 4. Handle Foreground Messages (app active)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('🔔 [FCM Foreground] Received message: ${message.notification?.title}');
          print('🔔 [FCM Foreground] Data payload: ${message.data}');
        }

        final notification = message.notification;
        final android = message.notification?.android;

        // Save incoming notification locally so it displays in Notifications screen
        if (notification != null) {
          final item = NotificationItem(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: notification.title ?? 'GetWork Alert',
            message: notification.body ?? '',
            createdAt: DateTime.now(),
            type: message.data['type']?.toString() ?? message.data['tab']?.toString() ?? 'system',
            isRead: false,
            data: message.data,
          );
          NotificationRepository.addNotification(item);
        }

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

  /// Get current device FCM token, save to Supabase, subscribe to FCM topics
  Future<String?> _fetchAndSaveFcmToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      if (kDebugMode) {
        print('==================================================');
        print('🔑 [FCM DEVICE TOKEN]:');
        print(_fcmToken);
        print('==================================================');
      }

      if (_fcmToken != null) {
        // Save to Supabase (non-blocking, best effort)
        await _saveFcmTokenToSupabase(_fcmToken!);
        // Subscribe to FCM topics based on saved user role
        await _subscribeToTopics();
      }

      return _fcmToken;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FCM Token Error]: $e');
      }
      return null;
    }
  }

  /// Save FCM token to Supabase `user_fcm_tokens` table
  Future<void> _saveFcmTokenToSupabase(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role') ?? 'worker';
      final platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

      final payload = <String, dynamic>{
        'token': token,
        'platform': platform,
        'user_role': role,
        'last_active_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (userId != null && userId.isNotEmpty) {
        payload['user_id'] = userId;
      }

      await Supabase.instance.client.from('user_fcm_tokens').upsert(
        payload,
        onConflict: 'token',
      );

      if (kDebugMode) {
        print('✅ [FCM Token saved to Supabase: user=${userId ?? "guest"} | role=$role | platform=$platform]');
      }
    } catch (e) {
      // Non-fatal — token will be saved on next launch
      if (kDebugMode) print('⚠️ [FCM Token Supabase Save Error]: $e');
    }
  }

  /// Subscribe device to FCM topics based on user role.
  /// Topics allow 1-call broadcasts without needing a token list.
  ///   Topic 'workers'    → all worker devices
  ///   Topic 'businesses' → all business devices
  ///   Topic 'all'        → everyone
  Future<void> _subscribeToTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role') ?? 'worker';

      // Always subscribe to 'all' topic for system broadcasts
      await _fcm.subscribeToTopic('all');

      // Subscribe to role-specific topic
      if (role == 'worker') {
        await _fcm.subscribeToTopic('workers');
        await _fcm.unsubscribeFromTopic('businesses');
      } else {
        await _fcm.subscribeToTopic('businesses');
        await _fcm.unsubscribeFromTopic('workers');
      }

      if (kDebugMode) {
        print('✅ [FCM Topics] Subscribed to: all + $role${role == 'worker' ? 's' : 'es'}');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [FCM Topic Subscribe Error]: $e');
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
