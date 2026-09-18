import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Push notifications via Firebase Cloud Messaging — mirrors eforward_app's
/// FirebaseNotificationService. Key platform rule (learned from eforward):
///   • iOS: Firebase is the sole notification delegate and displays banners
///     natively. flutter_local_notifications must NOT be initialized on iOS,
///     or it replaces Firebase's delegate and silently breaks iOS push.
///   • Android: FCM does not auto-show foreground notifications, so we display
///     them ourselves with flutter_local_notifications.
///
/// Firebase is initialized with the native config files (google-services.json /
/// GoogleService-Info.plist), so no generated firebase_options.dart is needed.

// Android channel — must match the manifest default_notification_channel_id.
const AndroidNotificationChannel kHrisChannel = AndroidNotificationChannel(
  'hris_notifications',
  'HRIS Notifications',
  description: 'Approvals and request updates',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

/// TOP-LEVEL background handler — Firebase runs this in its own isolate when the
/// app is terminated. Must be a top-level / static function.
@pragma('vm:entry-point')
Future<void> hrisFcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (Platform.isIOS) return; // APNs already displayed it.
  await _local.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await _local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(kHrisChannel);
  await PushService.showLocalNotification(message);
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// Set from main() so notification taps can navigate.
  static GlobalKey<NavigatorState>? navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) =>
      navigatorKey = key;

  bool _ready = false;

  /// Initialize FCM. Safe to call once at startup; no-op / logs on failure so a
  /// missing Firebase config never crashes the app.
  Future<void> initialize() async {
    if (_ready) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();

      await _requestPermissions();

      if (Platform.isAndroid) {
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(kHrisChannel);
        await _local.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
          onDidReceiveNotificationResponse: (r) =>
              _handlePayloadTap(r.payload),
        );
      }

      FirebaseMessaging.onBackgroundMessage(hrisFcmBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        await Future.delayed(const Duration(milliseconds: 600));
        _onNotificationTap(initial);
      }

      _ready = true;
      debugPrint('✅ PushService ready');
    } catch (e) {
      debugPrint('❌ PushService init skipped: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Show a system-tray notification (Android only; iOS displays via APNs).
  static Future<void> showLocalNotification(RemoteMessage message) async {
    if (Platform.isIOS) return;
    final title =
        message.notification?.title ?? message.data['title'] ?? 'ANI HRIS';
    final body = message.notification?.body ??
        message.data['body'] ??
        'You have a new notification';
    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kHrisChannel.id,
          kHrisChannel.name,
          channelDescription: kHrisChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    // Android must show it manually; iOS handled by presentation options.
    await showLocalNotification(message);
  }

  static void _onNotificationTap(RemoteMessage message) =>
      _navigate(message.data);

  static void _handlePayloadTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      _navigate(jsonDecode(payload) as Map<String, dynamic>);
    } catch (_) {}
  }

  /// Route based on the notification's `type` data field. Extend as needed.
  static void _navigate(Map<String, dynamic> data) {
    debugPrint('👆 Notification tapped: $data');
    // Example:
    // if (data['type'] == 'decision') { navigatorKey?.currentState?.push(...); }
  }

  /// The device FCM token. On iOS the APNs token must arrive first, so retry.
  Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        var apns = await FirebaseMessaging.instance.getAPNSToken();
        for (var i = 0; apns == null && i < 6; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          apns = await FirebaseMessaging.instance.getAPNSToken();
        }
        if (apns == null) {
          debugPrint('❌ APNs token null — upload the APNs .p8 key in Firebase.');
          return null;
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('getToken error: $e');
      return null;
    }
  }

  /// Called on token rotation (Google may re-issue the token).
  void onTokenRefresh(void Function(String token) handler) {
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen(handler);
    } catch (_) {}
  }
}
