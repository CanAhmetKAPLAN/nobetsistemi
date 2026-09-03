import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

/// Kullanıcının Açık/Koyu mod tercihini tutar, [AppTheme] renk paletini
/// buna göre günceller ve tercihi cihazda kalıcı hale getirir.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_is_dark';

  bool _isDark = true;

  bool get isDark => _isDark;

  ThemeProvider() {
    AppTheme.applyMode(_isDark);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefsKey);
    if (saved != null && saved != _isDark) {
      _isDark = saved;
      AppTheme.applyMode(_isDark);
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    AppTheme.applyMode(_isDark);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDark);
  }
}
