import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/group_session.dart';
import '../models/admin_vote.dart';
import '../models/group.dart';
import '../models/group_membership.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class GroupProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  List<Group> _myGroups = [];
  Group? _currentGroup;
  List<GroupMembership> _members = [];
  AdminVote? _activeVote;
  bool _loading = false;
  String? _error;

  List<Group> get myGroups => _myGroups;
  Group? get currentGroup => _currentGroup;
  List<GroupMembership> get members => _members;
  AdminVote? get activeVote => _activeVote;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchMyGroups(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(token: token);
      final data = await api.get(ApiConstants.groupsMine) as List;
      _myGroups = data.map((e) => Group.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Group> createGroup(String token, String name, String joinCode) async {
    final api = ApiService(token: token);
    final data = await api.post(ApiConstants.groups, {
      'name': name,
      'joinCode': joinCode,
    });
    final group = Group.fromJson(data);
    if (!_myGroups.any((g) => g.id == group.id)) {
      _myGroups = [..._myGroups, group];
    }
    await selectGroup(token, group);
    return group;
  }

  Future<Group> joinGroup(String token, String joinCode) async {
    final api = ApiService(token: token);
    final data = await api.post(ApiConstants.groupsJoin, {
      'joinCode': joinCode,
    });
    final group = Group.fromJson(data);
    if (!_myGroups.any((g) => g.id == group.id)) {
      _myGroups = [..._myGroups, group];
    }
    await selectGroup(token, group);
    return group;
  }

  Future<void> selectGroup(String token, Group group) async {
    _currentGroup = group;
    GroupSession.currentGroupId = group.id;
    await _authService.saveCurrentGroupId(group.id);
    notifyListeners();
  }

  /// Restores the previously-selected group (if any) from persisted
  /// storage. Treats a missing/invalid/no-longer-a-member group as "no
  /// selection" and leaves [currentGroup] null in that case.
  Future<void> restoreSelection(String token) async {
    final savedId = await _authService.getCurrentGroupId();
    if (savedId == null) {
      _currentGroup = null;
      return;
    }

    if (_myGroups.isEmpty) {
      await fetchMyGroups(token);
    }

    final stillMember = _myGroups.any((g) => g.id == savedId);
    if (!stillMember) {
      await _authService.clearCurrentGroupId();
      _currentGroup = null;
      notifyListeners();
      return;
    }

    try {
      final api = ApiService(token: token);
      final data = await api.get('${ApiConstants.groups}/$savedId');
      final group = Group.fromJson(data);
      _currentGroup = group;
      GroupSession.currentGroupId = group.id;
    } catch (e) {
      // 401/403/404 (or any other failure) => membership is no longer valid.
      await _authService.clearCurrentGroupId();
      GroupSession.currentGroupId = null;
      _currentGroup = null;
    }
    notifyListeners();
  }

  void clearGroup() {
    _currentGroup = null;
    _members = [];
    GroupSession.currentGroupId = null;
    _authService.clearCurrentGroupId();
    notifyListeners();
  }

  Future<List<GroupMembership>> fetchMembers(String token, String groupId) async {
    _loading = true;
    notifyListeners();
    try {
      final api = ApiService(token: token);
      final data = await api.get('${ApiConstants.groups}/$groupId/members') as List;
      _members = data.map((e) => GroupMembership.fromJson(e)).toList();
      return _members;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> regenerateJoinCode(String token, String groupId, String newJoinCode) async {
    final api = ApiService(token: token);
    final data = await api.post(
      '${ApiConstants.groups}/$groupId/regenerate-code',
      {'newJoinCode': newJoinCode},
    );
    return data['joinCode'] as String;
  }

  Future<void> updateMember(
    String token,
    String groupId,
    String userId, {
    String? role,
    bool? isActive,
  }) async {
    final api = ApiService(token: token);
    await api.put('${ApiConstants.groups}/$groupId/members/$userId', {
      'role': role,
      'isActive': isActive,
    });
    await fetchMembers(token, groupId);
  }

  Future<void> removeMember(String token, String groupId, String userId) async {
    final api = ApiService(token: token);
    await api.delete('${ApiConstants.groups}/$groupId/members/$userId');
    await fetchMembers(token, groupId);
  }

  Future<void> fetchActiveVote(String token, String groupId) async {
    final api = ApiService(token: token);
    final data = await api.get('${ApiConstants.groups}/$groupId/admin-vote');
    _activeVote = data == null ? null : AdminVote.fromJson(data);
    notifyListeners();
  }

  Future<void> startAdminVote(String token, String groupId, String candidateUserId) async {
    final api = ApiService(token: token);
    final data = await api.post(
      '${ApiConstants.groups}/$groupId/admin-vote',
      {'candidateUserId': candidateUserId},
    );
    _activeVote = AdminVote.fromJson(data);
    notifyListeners();
  }

  Future<void> castAdminVote(String token, String groupId, String voteId, bool approve) async {
    final api = ApiService(token: token);
    final data = await api.put(
      '${ApiConstants.groups}/$groupId/admin-vote/$voteId/cast',
      {'approve': approve},
    );
    _activeVote = AdminVote.fromJson(data);
    notifyListeners();
    if (_activeVote?.isPending == false) {
      await fetchMembers(token, groupId);
    }
  }

  Future<void> cancelAdminVote(String token, String groupId, String voteId) async {
    final api = ApiService(token: token);
    await api.delete('${ApiConstants.groups}/$groupId/admin-vote/$voteId');
    _activeVote = null;
    notifyListeners();
  }

  /// Sonuçlanmış (Passed/Rejected) bir oylama kartını sunucuya sormadan
  /// yerel olarak kapatır — kullanıcı "Tamam" dediğinde.
  void dismissVote() {
    _activeVote = null;
    notifyListeners();
  }
}
