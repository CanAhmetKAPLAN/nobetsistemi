import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan renk paleti.
///
/// Alanlar bilinçli olarak `const` değil — [applyMode] çağrıldığında
/// (bkz. `ThemeProvider`) çalışma zamanında Açık/Koyu moda göre güncellenir.
/// Bu sayede tüm ekranlar tek bir renk kaynağından beslenir; bir moddan
/// diğerine geçişte sadece bu değerler değişir, sayfa yapıları aynı kalır.
class AppTheme {
  static Color bg          = _darkBg;
  static Color panel       = _darkPanel;
  static Color panelLight  = _darkPanelLight;
  static Color border      = _darkBorder;

  static Color primary      = _darkPrimary;
  static Color primaryLight = _darkPrimaryLight;
  static Color accent       = _darkAccent;

  static Color textPrimary   = _darkTextPrimary;
  static Color textSecondary = _darkTextSecondary;

  static Color error     = _darkError;
  static Color warning   = _darkWarning;
  static Color success   = _darkSuccess;
  static Color secondary = _darkSecondary;

  static Color get surface    => panel;
  static Color get background => bg;

  static bool isDark = true;

  // ── Koyu palet (mevcut taktik yeşil tema) ──────────────────────────────────
  static const Color _darkBg           = Color(0xFF121212);
  static const Color _darkPanel        = Color(0xFF1F2329);
  static const Color _darkPanelLight   = Color(0xFF252B34);
  static const Color _darkBorder       = Color(0xFF2A3040);
  static const Color _darkPrimary      = Color(0xFF2E7D32);
  static const Color _darkPrimaryLight = Color(0xFF4CAF50);
  static const Color _darkAccent       = Color(0xFF66BB6A);
  static const Color _darkTextPrimary  = Color(0xFFE8EAED);
  static const Color _darkTextSecondary= Color(0xFF8A9099);
  static const Color _darkError        = Color(0xFFCF6679);
  static const Color _darkWarning      = Color(0xFFFFB74D);
  static const Color _darkSuccess      = Color(0xFF4CAF50);
  static const Color _darkSecondary    = Color(0xFF37474F);

  // ── Açık palet (teal/beyaz tema) ────────────────────────────────────────────
  static const Color _lightBg           = Color(0xFFF8FAFC);
  static const Color _lightPanel        = Color(0xFFFFFFFF);
  static const Color _lightPanelLight   = Color(0xFFF1F5F9);
  static const Color _lightBorder       = Color(0xFFE2E8F0);
  static const Color _lightPrimary      = Color(0xFF0D9488);
  static const Color _lightPrimaryLight = Color(0xFF14B8A6);
  static const Color _lightAccent       = Color(0xFF0F766E);
  static const Color _lightTextPrimary  = Color(0xFF0F172A);
  static const Color _lightTextSecondary= Color(0xFF64748B);
  static const Color _lightError        = Color(0xFFDC2626);
  static const Color _lightWarning      = Color(0xFFF59E0B);
  static const Color _lightSuccess      = Color(0xFF10B981);
  static const Color _lightSecondary    = Color(0xFF475569);

  /// [ThemeProvider] tarafından mod değişince çağrılır; tüm renk alanlarını
  /// yeni moda göre günceller.
  static void applyMode(bool dark) {
    isDark = dark;
    bg            = dark ? _darkBg            : _lightBg;
    panel         = dark ? _darkPanel         : _lightPanel;
    panelLight    = dark ? _darkPanelLight    : _lightPanelLight;
    border        = dark ? _darkBorder        : _lightBorder;
    primary       = dark ? _darkPrimary       : _lightPrimary;
    primaryLight  = dark ? _darkPrimaryLight  : _lightPrimaryLight;
    accent        = dark ? _darkAccent        : _lightAccent;
    textPrimary   = dark ? _darkTextPrimary   : _lightTextPrimary;
    textSecondary = dark ? _darkTextSecondary : _lightTextSecondary;
    error         = dark ? _darkError         : _lightError;
    warning       = dark ? _darkWarning       : _lightWarning;
    success       = dark ? _darkSuccess       : _lightSuccess;
    secondary     = dark ? _darkSecondary     : _lightSecondary;
  }

  // ── ThemeData — güncel renklerden anlık üretilir ────────────────────────────
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: isDark
        ? ColorScheme.dark(
            primary: primary, secondary: primaryLight, surface: panel,
            error: error, onPrimary: Colors.white, onSurface: textPrimary,
          )
        : ColorScheme.light(
            primary: primary, secondary: primaryLight, surface: panel,
            error: error, onPrimary: Colors.white, onSurface: textPrimary,
          ),
    scaffoldBackgroundColor: bg,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: panel,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: panel,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: textPrimary,
      iconColor: textSecondary,
    ),
    dividerColor: border,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      filled: true,
      fillColor: panelLight,
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryLight),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        side: BorderSide(color: primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: panelLight,
      labelStyle: TextStyle(color: textPrimary),
      side: BorderSide(color: border),
    ),
    textTheme: TextTheme(
      bodyLarge:  TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall:  TextStyle(color: textSecondary),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      titleMedium:TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textSecondary),
    ),
    iconTheme: IconThemeData(color: textSecondary),
    dialogTheme: DialogThemeData(
      backgroundColor: panel,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: panelLight,
      contentTextStyle: TextStyle(color: textPrimary),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(panel),
      ),
    ),
  );
}
