import 'package:flutter/material.dart';

/// Uygulama genelinde (ör. FCM bildirim dokunuşlarında, BuildContext
/// olmayan servis sınıflarından) sayfa yönlendirmesi yapabilmek için
/// paylaşılan navigator anahtarı.
final navigatorKey = GlobalKey<NavigatorState>();
