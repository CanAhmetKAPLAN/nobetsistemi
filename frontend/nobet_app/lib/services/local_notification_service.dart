import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Nöbet öncesi hatırlatma: nöbet gününden 1 gün önce sabah 09:00
  static Future<void> scheduleDutyReminder({
    required int id,
    required DateTime dutyDate,
    required String userName,
  }) async {
    if (kIsWeb) return;

    final reminderDate = dutyDate.subtract(const Duration(days: 1));
    final scheduled = DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9, 0);

    if (scheduled.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      '⏰ Nöbet Hatırlatması',
      'Yarın (${_fmt(dutyDate)}) nöbetiniz var.',
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'duty_reminder',
          'Nöbet Hatırlatmaları',
          channelDescription: '1 gün öncesi hatırlatma',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(badgeNumber: 1),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'duty_reminder_$id',
    );
  }

  // Nöbet günü sabah 07:00 bildirimi
  static Future<void> scheduleDutyDay({
    required int id,
    required DateTime dutyDate,
  }) async {
    if (kIsWeb) return;

    final scheduled = DateTime(dutyDate.year, dutyDate.month, dutyDate.day, 7, 0);
    if (scheduled.isBefore(DateTime.now())) return;

    // id çakışmasını önlemek için farklı offset
    await _plugin.zonedSchedule(
      id + 10000,
      '🏥 Bugün Nöbetsiniz!',
      '${_fmt(dutyDate)} tarihli nöbetiniz bugün.',
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'duty_today',
          'Nöbet Günü',
          channelDescription: 'Nöbet günü sabah bildirimi',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(badgeNumber: 1),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'duty_today_$id',
    );
  }

  // Anlık bildirim (izin/swap sonucu için)
  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant',
          'Anlık Bildirimler',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(badgeNumber: 1),
      ),
      payload: payload,
    );
  }

  static Future<void> cancelDutyNotifications(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
    await _plugin.cancel(id + 10000);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}
