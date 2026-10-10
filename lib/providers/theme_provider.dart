import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const _themeKey = 'themeDark';

final themeControllerProvider = StateNotifierProvider<ThemeController, bool>((ref) {
  return ThemeController();
});

class ThemeController extends StateNotifier<bool> {
  ThemeController() : super(false) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_themeKey) ?? false;
    // FIX (theme toggle not working): the real screen colors come from
    // AppPalette.isDark, but that value was never updated together with the
    // state (MaterialApp themeMode), so toggling never visibly switched
    // between dark and light. Set the palette first, then the state, so the
    // rebuild picks up the new colors.
    AppPalette.isDark = dark;
    state = dark;
  }

  Future<void> setDark(bool dark) async {
    AppPalette.isDark = dark;
    state = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, dark);
  }
}