import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/navigation.dart';
import 'api_service.dart';
import 'local_notification_service.dart';

// Top-level: uygulama arka planda/kapalıyken tetiklenir
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _handleMessage(message);
}

Future<void> _handleMessage(RemoteMessage message) async {
  final type = message.data['type'] ?? '';
  final title = message.notification?.title ?? _titleFor(type);
  final body = message.notification?.body ?? '';

  final id = DateTime.now().millisecondsSinceEpoch % 100000;

  await LocalNotificationService.showInstant(
    id: id,
    title: title,
    body: body,
    payload: type,
  );
}

/// Bildirim türüne göre uygulama içinde açılacak sayfa — dokunulduğunda
/// kullanıcıyı ilgili ekrana götürür (ör. nöbet değişim bildirimleri
/// doğrudan değişim sayfasını açar).
String? _routeFor(String type) => switch (type) {
      'swap_request' || 'swap_approved' || 'swap_rejected' => '/swaps',
      'leave_approved' || 'leave_rejected' => '/leaves',
      'duty_reminder' || 'duty_today' || 'duty_assigned' || 'duty_reassigned' =>
        '/monthly-calendar',
      _ => null,
    };

void _navigateForMessage(RemoteMessage message) {
  final type = message.data['type'] ?? '';
  final route = _routeFor(type);
  if (route == null) return;
  navigatorKey.currentState?.pushNamed(route);
}

String _titleFor(String type) => switch (type) {
      'leave_approved' => '✅ İzin Onaylandı',
      'leave_rejected' => '❌ İzin Reddedildi',
      'swap_request' => '🔄 Nöbet Değişim Talebi',
      'swap_approved' => '✅ Değişim Onaylandı',
      'swap_rejected' => '❌ Değişim Reddedildi',
      'duty_reminder' => '⏰ Nöbet Hatırlatması',
      'duty_today' => '🏥 Bugün Nöbetsiniz',
      _ => 'Nöbet Sistemi',
    };

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static const _tokenKey = 'fcm_token';

  static Future<void> init({String? authToken}) async {
    await _requestPermission();
    await _setupHandlers();
    await _registerToken(authToken: authToken);
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('FCM izin: ${settings.authorizationStatus}');
    }
  }

  static Future<void> _setupHandlers() async {
    // Uygulama arka planda (background handler global fonksiyon)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Uygulama açıkken gelen mesajlar
    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode) debugPrint('FCM foreground: ${message.data}');
      await _handleMessage(message);
    });

    // Bildirime tıklanınca (uygulama arka plandayken)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) debugPrint('FCM opened: ${message.data}');
      _navigateForMessage(message);
    });

    // Uygulama tamamen kapalıyken bir bildirime dokunularak açıldıysa
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _navigateForMessage(initialMessage);
    }

    // Web için ön plan bildirimleri göster
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _registerToken({String? authToken}) async {
    final token = await _messaging.getToken(
      // 🔧 VAPID anahtarını Firebase Console → Cloud Messaging → Web Push certificates'tan al
      vapidKey: kIsWeb ? 'BIjB9caeDTjU8oIr-PVeHGWLNX_gblCB7FozRijpnv-S1aTTWG1klNc7PSUn5BAxsNTc0SqagfxM9prF2KwqpII' : null,
    );
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);

    // Token değişmişse backend'e kaydet
    if (token != saved && authToken != null) {
      await _sendTokenToBackend(token, authToken);
    }
    await prefs.setString(_tokenKey, token);

    if (kDebugMode) debugPrint('FCM Token: $token');

    // Token yenilenince tekrar kaydet
    _messaging.onTokenRefresh.listen((newToken) async {
      await prefs.setString(_tokenKey, newToken);
      if (authToken != null) await _sendTokenToBackend(newToken, authToken);
    });
  }

  static Future<void> _sendTokenToBackend(String fcmToken, String authToken) async {
    try {
      final api = ApiService(token: authToken);
      await api.post('${ApiConstants.users}/fcm-token', {'fcmToken': fcmToken});
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token backend kaydı başarısız: $e');
    }
  }

  static Future<String?> getToken() async {
    return _messaging.getToken(
      vapidKey: kIsWeb ? 'BIjB9caeDTjU8oIr-PVeHGWLNX_gblCB7FozRijpnv-S1aTTWG1klNc7PSUn5BAxsNTc0SqagfxM9prF2KwqpII' : null,
    );
  }
}
