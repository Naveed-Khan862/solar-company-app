import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solar_company_project/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders with email/password form',
      (WidgetTester tester) async {
    // Mock LocalStorage (shared_preferences) in test mode.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    // Let the repositories initialize (Firebase is not available in this test
    // environment — _safeLoad swallows that failure and the UI still renders).
    await tester.pump();

    expect(find.text('MFES'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
