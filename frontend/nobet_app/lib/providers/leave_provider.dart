import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/group_session.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';

class LeaveProvider extends ChangeNotifier {
  List<LeaveRequest> _leaves = [];
  List<LeaveRequest> _pending = [];
  bool _loading = false;
  String? _error;

  List<LeaveRequest> get leaves => _leaves;
  List<LeaveRequest> get pending => _pending;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchMy(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data = await api.get(ApiConstants.leavesMy) as List;
      _leaves = data.map((e) => LeaveRequest.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAll(String token) async {
    _loading = true;
    notifyListeners();
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data = await api.get(ApiConstants.leaves) as List;
      _leaves = data.map((e) => LeaveRequest.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPending(String token) async {
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data = await api.get(ApiConstants.leavesPending) as List;
      _pending = data.map((e) => LeaveRequest.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> create(String token, DateTime start, DateTime end, String? reason) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    final body = <String, dynamic>{
      'startDate': start.toUtc().toIso8601String(),
      'endDate': end.toUtc().toIso8601String(),
    };
    if (reason != null) body['reason'] = reason;
    await api.post(ApiConstants.leaves, body);
    await fetchMy(token);
  }

  Future<void> review(String token, String id, bool approve) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    await api.put('${ApiConstants.leaves}/$id/review', {'approve': approve});
    await fetchPending(token);
    await fetchAll(token);
  }
}
