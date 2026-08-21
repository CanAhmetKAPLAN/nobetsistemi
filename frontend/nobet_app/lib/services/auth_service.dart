import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'jwt_token';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _currentGroupIdKey = 'current_group_id';

  Future<Map<String, String>> login(String email, String password) async {
    final api = ApiService();
    final data = await api.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });
    await _saveSession(data);
    return {'token': data['token']};
  }

  Future<Map<String, String>> register(String name, String email, String password) async {
    final api = ApiService();
    final data = await api.post(ApiConstants.register, {
      'name': name,
      'email': email,
      'password': password,
    });
    await _saveSession(data);
    return {'token': data['token']};
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data['token']);
    await prefs.setString(_nameKey, data['name']);
    await prefs.setString(_emailKey, data['email']);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<User?> getMe(String token) async {
    try {
      final api = ApiService(token: token);
      final data = await api.get(ApiConstants.usersMe);
      return User.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCurrentGroupId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentGroupIdKey, id);
  }

  Future<String?> getCurrentGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentGroupIdKey);
  }

  Future<void> clearCurrentGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentGroupIdKey);
  }
}
