import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/group_session.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> fetch(String token) async {
    _loading = true;
    notifyListeners();
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data = await api.get(ApiConstants.notifications) as List;
      _notifications = data.map((e) => AppNotification.fromJson(e)).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String token, String id) async {
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      await api.put('${ApiConstants.notifications}/$id/read', {});
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        final n = _notifications[idx];
        _notifications[idx] = AppNotification(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead(String token) async {
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      await api.put(ApiConstants.notificationsReadAll, {});
      _notifications = _notifications
          .map((n) => AppNotification(
                id: n.id,
                userId: n.userId,
                title: n.title,
                message: n.message,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
