import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solar_company_project/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders with email/password form',
      (WidgetTester tester) async {
    // LocalStorage (shared_preferences) ko test-mode mein mock karo.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    // Repositories initialize hone den (Firebase is test env mein available
    // nahi — _safeLoad use fail hone par empty state dega, UI phir bhi dikhega).
    await tester.pump();

    expect(find.text('Solar Company'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
