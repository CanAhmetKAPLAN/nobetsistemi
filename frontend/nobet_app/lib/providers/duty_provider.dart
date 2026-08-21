import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/group_session.dart';
import '../models/duty.dart';
import '../models/monthly_score.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';

class DutyProvider extends ChangeNotifier {
  List<Duty> _duties = [];
  List<Duty> _monthlyDuties = [];
  List<Duty> _weeklyDuties = [];
  List<MonthlyScore> _monthlyScores = [];
  bool _loading = false;
  bool _monthlyLoading = false;
  String? _error;

  List<MonthlyScore> get monthlyScores => _monthlyScores;
  List<Duty> get duties => _duties;
  List<Duty> get monthlyDuties => _monthlyDuties;
  List<Duty> get weeklyDuties => _weeklyDuties;
  bool get loading => _loading;
  bool get monthlyLoading => _monthlyLoading;
  String? get error => _error;

  Future<void> fetchAll(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data = await api.get(ApiConstants.duties) as List;
      _duties = data.map((e) => Duty.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchByUser(String token, String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data =
          await api.get('${ApiConstants.duties}/by-user/$userId') as List;
      _duties = data.map((e) => Duty.fromJson(e)).toList();
      await _scheduleNotificationsForDuties(_duties);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleNotificationsForDuties(List<Duty> duties) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    for (final duty in duties) {
      final dutyDate = DateTime.tryParse(duty.date);
      if (dutyDate == null || !dutyDate.isAfter(now)) continue;
      final id = duty.id.hashCode.abs() % 9000;
      await LocalNotificationService.scheduleDutyReminder(
        id: id,
        dutyDate: dutyDate,
        userName: duty.userName,
      );
      await LocalNotificationService.scheduleDutyDay(
        id: id,
        dutyDate: dutyDate,
      );
    }
  }

  Future<void> autoAssign(String token, DateTime date) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    await api.post(ApiConstants.dutiesAutoAssign, {
      'date': date.toUtc().toIso8601String(),
    });
    await fetchAll(token);
  }

  Future<void> createManual(
    String token,
    String userId,
    DateTime date,
    String? notes,
  ) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    await api.post(ApiConstants.dutiesManual, {
      'userId': userId,
      'date': date.toUtc().toIso8601String(),
      'notes': ?notes,
    });
    await fetchAll(token);
  }

  Future<void> fetchByMonth(String token, int year, int month) async {
    _monthlyLoading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data =
          await api.get('${ApiConstants.dutiesByMonth}?year=$year&month=$month')
              as List;
      _monthlyDuties = data.map((e) => Duty.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _monthlyLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> autoFillMonth(
    String token,
    int year,
    int month,
  ) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    final result =
        await api.post(ApiConstants.dutiesAutoFillMonth, {
              'year': year,
              'month': month,
            })
            as Map<String, dynamic>;
    await fetchByMonth(token, year, month);
    return result;
  }

  Future<void> fetchMonthlyScores(String token) async {
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data = await api.get(ApiConstants.dutiesMonthlyScores) as List;
      _monthlyScores = data.map((e) => MonthlyScore.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchWeekly(String token) async {
    try {
      final now = DateTime.now();
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data =
          await api.get(
                '${ApiConstants.dutiesByMonth}?year=${now.year}&month=${now.month}',
              )
              as List;
      _weeklyDuties = data.map((e) => Duty.fromJson(e)).toList();
      // Hafta ay sonuna taşıyorsa bir sonraki ayı da çek
      final weekEnd = now.add(const Duration(days: 7));
      if (weekEnd.month != now.month) {
        final nextData =
            await api.get(
                  '${ApiConstants.dutiesByMonth}?year=${weekEnd.year}&month=${weekEnd.month}',
                )
                as List;
        _weeklyDuties = [
          ..._weeklyDuties,
          ...nextData.map((e) => Duty.fromJson(e)),
        ];
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> delete(String token, String dutyId) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    await api.delete('${ApiConstants.duties}/$dutyId');
    _duties.removeWhere((d) => d.id == dutyId);
    notifyListeners();
  }
}
