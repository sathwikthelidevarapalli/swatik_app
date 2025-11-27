// This test verifies that the key elements of the SwastikSplashScreen are correctly rendered.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Assuming your main app logic is in the main.dart file.
// We import the entire app, which contains the SwastikSplashScreen.
import 'package:swastik_app/main.dart';

void main() {
  // Test Group for the Swastik Splash Screen
  group('SwastikSplashScreen Tests', () {
    testWidgets('Renders all required text and the CTA button', (WidgetTester tester) async {
      // Build our main app widget (MyApp) and trigger a frame.
      // This will load the SwastikSplashScreen defined in the previous code.
      await tester.pumpWidget(MyApp());

      // 1. Verify the presence of the main text elements.
      expect(find.text('Swastik'), findsOneWidget, reason: 'Should find the main project title.');
      expect(find.text('Your One-Stop Event Planner'), findsOneWidget, reason: 'Should find the tagline.');

      // 2. Verify the presence of the navigation links.
      expect(find.text('Plan'), findsOneWidget, reason: 'Should find the "Plan" link.');
      expect(find.text('Book'), findsOneWidget, reason: 'Should find the "Book" link.');
      expect(find.text('Celebrate'), findsOneWidget, reason: 'Should find the "Celebrate" link.');

      // 3. Verify the presence of the main Call-to-Action button.
      final ctaButtonFinder = find.widgetWithText(ElevatedButton, 'Get Started');
      expect(ctaButtonFinder, findsOneWidget, reason: 'Should find the "Get Started" button.');

      // 4. Optionally, verify that tapping the button works (even if it does nothing yet).
      await tester.tap(ctaButtonFinder);
      await tester.pump();
      // Since the button's onPressed is empty, no state change is expected,
      // but we confirm the tap interaction was successful.
    });

    // You can add more tests here, for example, to check the colors or sizes if needed.
  });
}
