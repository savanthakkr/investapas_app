import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

/// Called by the OS when a notification arrives while the app is terminated
/// or in the background. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;

  /// Call once from main() after Firebase.initializeApp().
  Future<void> init({
    /// Called when user taps a notification (foreground or from tray).
    void Function(RemoteMessage message)? onNotificationTap,
  }) async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission (Android 13+, iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get & upload initial token
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
      await _uploadToken(token);
    }

    // Re-upload whenever token rotates
    _messaging.onTokenRefresh.listen(_uploadToken);

    // ── Foreground notification handler ──────────────────────────────────
    // Android does NOT auto-display FCM notifications when the app is open,
    // so we show an in-app toast using OKToast (which wraps the root widget).
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? '';
      final body  = message.notification?.body  ?? '';
      debugPrint('[FCM] Foreground message: $title');
      if (title.isEmpty && body.isEmpty) return;
      final text = body.isNotEmpty ? '$title\n$body' : title;
      showToast(
        text,
        duration:        const Duration(seconds: 4),
        position:        ToastPosition.top,
        backgroundColor: const Color(0xFF1C1C2E),
        radius:          12,
        textStyle: const TextStyle(
          color:    Colors.white,
          fontSize: 13,
          height:   1.45,
        ),
      );
    });

    // ── Notification tap (app in background/foreground) ──────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Notification tapped (background): ${message.data}');
      onNotificationTap?.call(message);
    });

    // ── App opened from terminated state via notification ─────────────────
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] App launched from notification: ${initial.data}');
      onNotificationTap?.call(initial);
    }
  }

  Future<void> _uploadToken(String token) async {
    try {
      await ApiHelper.put(ApiEndpoints.profileUpdateFcmTokenApi, {
        'fcmToken': token,
      });
      debugPrint('[FCM] Token uploaded to backend');
    } catch (e) {
      debugPrint('[FCM] Token upload failed: $e');
    }
  }

  /// Send a test notification to a specific FCM token from the backend.
  /// Only for debug builds — production uses the backend directly.
  Future<String?> getToken() => _messaging.getToken();
}
