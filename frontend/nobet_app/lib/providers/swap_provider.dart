import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/group_session.dart';
import '../models/swap_request.dart';
import '../services/api_service.dart';

class SwapProvider extends ChangeNotifier {
  List<SwapRequest> _swaps = [];
  List<SwapRequest> _pending = [];
  bool _loading = false;
  String? _error;

  List<SwapRequest> get swaps => _swaps;
  List<SwapRequest> get pending => _pending;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchMy(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
      final data = await api.get(ApiConstants.swapsMy) as List;
      _swaps = data.map((e) => SwapRequest.fromJson(e)).toList();
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
      final data = await api.get(ApiConstants.swaps) as List;
      _swaps = data.map((e) => SwapRequest.fromJson(e)).toList();
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
      final data = await api.get(ApiConstants.swapsPending) as List;
      _pending = data.map((e) => SwapRequest.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> create(
    String token,
    String targetUserId,
    String requesterDutyId,
    String? targetDutyId,
    String reason,
  ) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    await api.post(ApiConstants.swaps, {
      'targetUserId': targetUserId,
      'requesterDutyId': requesterDutyId,
      'targetDutyId': ?targetDutyId,
      'reason': reason,
    });
    await fetchMy(token);
  }

  Future<void> review(String token, String id, bool approve) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    await api.put('${ApiConstants.swaps}/$id/review', {'approve': approve});
    await fetchPending(token);
    await fetchAll(token);
  }

  Future<void> cancel(String token, String id) async {
    final api = ApiService(token: token, groupId: GroupSession.currentGroupId);
    await api.put('${ApiConstants.swaps}/$id/cancel', {});
    await fetchMy(token);
  }
}
