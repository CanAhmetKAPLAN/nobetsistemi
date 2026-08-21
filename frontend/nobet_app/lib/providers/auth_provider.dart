import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/local_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  User? _user;
  String? _token;
  bool _loading = true;

  User? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    _token = await _service.getToken();
    if (_token != null) {
      _user = await _service.getMe(_token!);
      if (_user == null) {
        await _service.logout();
        _token = null;
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await _service.login(email, password);
    _token = result['token'];
    _user = await _service.getMe(_token!);
    await FcmService.init(authToken: _token);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final result = await _service.register(name, email, password);
    _token = result['token'];
    _user = await _service.getMe(_token!);
    await FcmService.init(authToken: _token);
    notifyListeners();
  }

  Future<void> logout() async {
    await LocalNotificationService.cancelAll();
    await _service.logout();
    _token = null;
    _user = null;
    notifyListeners();
  }
}
