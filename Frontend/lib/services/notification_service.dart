import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    final token = await _fcm.getToken();
    if (token != null) {
      // Store token for sending to backend on login
      _cachedToken = token;
    }
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static String? _cachedToken;
  static String? get fcmToken => _cachedToken;

  static void _handleForegroundMessage(RemoteMessage message) {
    // In-app notification handling
    final notification = message.notification;
    if (notification != null) {
      // Could show a SnackBar or local notification
    }
  }

  static Future<void> refreshToken() async {
    _cachedToken = await _fcm.getToken();
  }
}
