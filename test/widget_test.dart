// Basic smoke test for the Ardent HR app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hris_mobile/main.dart';

void main() {
  testWidgets('Login screen renders and navigates to dashboard',
      (WidgetTester tester) async {
    // Render in a generous viewport. Widget tests use a fixed-width test font
    // (every glyph is a square), so text measures wider than on real devices;
    // the extra width avoids false-positive horizontal overflow in the test.
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const HrisApp());
    await tester.pumpAndSettle();

    // Login screen is shown first.
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Sign in navigates to the dashboard shell (bottom nav is always built).
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Payroll'), findsWidgets);
    expect(find.text('Welcome back'), findsNothing);
  });
}
