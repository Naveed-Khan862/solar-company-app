import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_company_project/providers/theme_provider.dart';
import 'package:solar_company_project/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('app start: saved dark theme is applied to AppPalette too',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'themeDark': true});
    AppPalette.isDark = false;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeControllerProvider); // creates the controller
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Regression for the fix: before, only the state changed and AppPalette
    // isDark stayed false — so toggling the theme changed no colors.
    expect(container.read(themeControllerProvider), true);
    expect(AppPalette.isDark, true);
  });

  test('setDark(true) updates state, palette and persistence', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppPalette.isDark = false;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(themeControllerProvider), false);

    await container.read(themeControllerProvider.notifier).setDark(true);

    expect(container.read(themeControllerProvider), true);
    expect(AppPalette.isDark, true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('themeDark'), true);
  });

  test('setDark(false) → switches back to light theme', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'themeDark': true});
    AppPalette.isDark = true;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container.read(themeControllerProvider.notifier).setDark(false);

    expect(container.read(themeControllerProvider), false);
    expect(AppPalette.isDark, false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('themeDark'), false);
  });
}
