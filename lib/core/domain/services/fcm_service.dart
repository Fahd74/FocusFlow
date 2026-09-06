import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles FCM token registration and foreground message display.
/// Background/terminated FCM messages are shown automatically by the OS.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM: request permission, register token, listen to messages.
  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      // Request notification permission (Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      // Get and store the FCM token
      await _refreshAndStoreFcmToken();

      // Listen for token refresh (e.g. after app reinstall)
      FirebaseMessaging.instance.onTokenRefresh.listen(_storeFcmToken);

      // Initialize local notifications for foreground FCM display
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotifications.initialize(settings: initSettings);

      // Show notification when app is in foreground and FCM message arrives
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    } catch (e) {
      debugPrint('FcmService init error: $e');
    }
  }

  Future<void> _refreshAndStoreFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeFcmToken(token);
      }
    } catch (e) {
      debugPrint('FCM token fetch error: $e');
    }
  }

  Future<void> _storeFcmToken(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);
      debugPrint('FCM token stored in Supabase');
    } catch (e) {
      debugPrint('FCM token store error: $e');
    }
  }

  /// Clear the FCM token in Supabase upon user sign-out to prevent orphaned pushes
  Future<void> clearFcmToken() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('users')
          .update({'fcm_token': null})
          .eq('id', userId);
      debugPrint('FCM token cleared in Supabase on sign-out');
    } catch (e) {
      debugPrint('FCM token clear error: $e');
    }
  }

  /// Handle FCM message while app is in foreground — show local notification.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null) return;

    // Use positive 31-bit integer mask to prevent negative Android notification ID crashes
    final notificationId = notification.hashCode & 0x7FFFFFFF;

    await _localNotifications.show(
      id: notificationId,
      title: notification.title ?? 'FocusFlow',
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'focusflow_reminders_v2',
          'Task Reminders',
          channelDescription: 'FocusFlow task reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          enableVibration: true,
          actions: const [
            AndroidNotificationAction(
              'mark_done',
              'Mark as Done',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: message.data['task_id'],
    );
  }
}

