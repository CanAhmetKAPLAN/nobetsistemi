import 'package:flutter/material.dart';

class AppTheme {
  // ── Tactical dark palette ───────────────────────────────────────────────────
  static const Color bg          = Color(0xFF121212);
  static const Color panel       = Color(0xFF1F2329);
  static const Color panelLight  = Color(0xFF252B34);
  static const Color border      = Color(0xFF2A3040);

  static const Color primary     = Color(0xFF2E7D32); // tactical green
  static const Color primaryLight= Color(0xFF4CAF50);
  static const Color accent      = Color(0xFF66BB6A);

  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF8A9099);

  static const Color error   = Color(0xFFCF6679);
  static const Color warning = Color(0xFFFFB74D);
  static const Color success = Color(0xFF4CAF50);

  // Keep for legacy references in non-dashboard screens
  static const Color secondary   = Color(0xFF37474F);
  static const Color surface     = panel;
  static const Color background  = bg;

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryLight,
      surface: panel,
      error: error,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: bg,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: panel,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: panel,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: textPrimary,
      iconColor: textSecondary,
    ),
    dividerColor: border,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      filled: true,
      fillColor: panelLight,
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
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
        side: const BorderSide(color: primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: panelLight,
      labelStyle: TextStyle(color: textPrimary),
      side: BorderSide(color: border),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall:  TextStyle(color: textSecondary),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      titleMedium:TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textSecondary),
    ),
    iconTheme: const IconThemeData(color: textSecondary),
    dialogTheme: const DialogThemeData(
      backgroundColor: panel,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: panelLight,
      contentTextStyle: TextStyle(color: textPrimary),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(panel),
      ),
    ),
  );

  // Keep light for fallback
  static ThemeData get light => dark;
}
