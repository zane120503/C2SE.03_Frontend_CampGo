// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:CampGo/main.dart';
import 'package:CampGo/providers/auth_provider.dart';
import 'package:CampGo/models/user_model.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Tạo AuthProvider với người dùng mẫu cho testing
    final authProvider = AuthProvider();
    final testUser = UserProfile(
      id: 'test_user_id',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phoneNumber: '0123456789',
      isProfileCompleted: true,
      gender: 'male',
    );
    authProvider.setUser(testUser);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(authProvider: authProvider));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
