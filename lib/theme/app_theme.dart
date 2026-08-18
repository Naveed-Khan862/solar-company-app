import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPalette {
  static bool isDark = false;

  static Color get textPrimary =>
      isDark ? const Color(0xFFE8F5EE) : const Color(0xFF1B2E24);
  static Color get textSecondary =>
      isDark ? const Color(0xFFB9CFC3) : const Color(0xFF35524A);
  static Color get textMuted =>
      isDark ? const Color(0xFF8BA497) : const Color(0xFF7A8A80);
  static Color get textFaint =>
      isDark ? const Color(0xFF677E72) : const Color(0xFF9AABA0);
  static Color get surface =>
      isDark ? const Color(0xFF16241C) : Colors.white;
  static Color get surfaceSoft =>
      isDark ? const Color(0xFF1D3026) : const Color(0xFFF4F9F6);
  static Color get border =>
      isDark ? const Color(0xFF294132) : const Color(0xFFDDE9E1);
  static Color get track =>
      isDark ? const Color(0xFF24382D) : const Color(0xFFE8F1EC);
  static Color get cardBorder =>
      isDark ? const Color(0xFF2A4134) : const Color(0xFFE3EDE6);
  static Color get shadow =>
      isDark ? Colors.black : const Color(0xFF9EB5A8);
  static Color get appBgTop =>
      isDark ? const Color(0xFF0B1510) : const Color(0xFFF2F9F4);
  static Color get appBgMid =>
      isDark ? const Color(0xFF12241A) : const Color(0xFFFDFBF3);
  static Color get appBgBottom =>
      isDark ? const Color(0xFF0F1F17) : const Color(0xFFF0F6F2);
  static Color get orbGreen =>
      isDark ? const Color(0xFF1E4D34) : const Color(0xFFA8E6C1);
  static Color get orbGold =>
      isDark ? const Color(0xFF4A3A14) : const Color(0xFFFFE6A8);
  static Color get orbBlue =>
      isDark ? const Color(0xFF1D4054) : const Color(0xFFBCE7F5);
  static Color get gridLine =>
      isDark ? const Color(0xFF7FB592) : const Color(0xFF4E7A5F);

  static const primary = Color(0xFF00A86B);
  static const primaryLight = Color(0xFF00C97D);
  static const gold = Color(0xFFFFB300);
}

class ThemeController extends ValueNotifier<bool> {
  ThemeController._() : super(false);

  static final ThemeController instance = ThemeController._();

  static const _key = 'themeDark';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_key) ?? false;
    AppPalette.isDark = dark;
    value = dark;
  }

  Future<void> setDark(bool dark) async {
    AppPalette.isDark = dark;
    value = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, dark);
  }
}
