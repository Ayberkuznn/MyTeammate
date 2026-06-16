import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_service.dart';

class PushNotificationService {
  static final _messaging = FirebaseMessaging.instance;

  /// Bildirim izni ister, FCM token'ını alır ve backend'e kaydeder.
  /// Token değiştiğinde de otomatik olarak günceller.
  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await AuthService.updateFcmToken(token);
    }

    _messaging.onTokenRefresh.listen(AuthService.updateFcmToken);
  }
}
