// This is a basic Flutter widget test for the AI Tourist Guide app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tourist_guide/main.dart';

void main() {
  testWidgets('AI Tourist Guide app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen is displayed.
    expect(find.text('AI Tourist Guide'), findsOneWidget);
    expect(find.text('Your Smart Travel Companion'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
