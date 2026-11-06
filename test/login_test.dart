import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidz_store/admin_access.dart';
import 'package:kidz_store/admin_dashboard.dart';
import 'package:kidz_store/login.dart';

import 'support/auth_fakes.dart';

void main() {
  testWidgets(
      'invalid login uses Auth, preserves password whitespace and hides raw errors',
      (tester) async {
    final auth = StoreAuthFake()
      ..loginError = const AuthException('sensitive upstream detail');
    final client = StoreClientFake(auth);
    await tester.pumpWidget(
        MaterialApp(home: LoginRegisterScreen(access: AdminAccess(client))));
    await tester.enterText(
        find.byType(TextFormField).at(0), '  synthetic@example.test  ');
    await tester.enterText(
        find.byType(TextFormField).at(1), ' synthetic password ');
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(auth.submittedEmail, 'synthetic@example.test');
    expect(auth.submittedPassword, ' synthetic password ');
    expect(find.textContaining('Unable to sign in.'), findsOneWidget);
    expect(find.textContaining('sensitive upstream detail'), findsNothing);
    expect(client.reads, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await auth.events.close();
  });

  testWidgets('Admin login enters the guarded original dashboard',
      (tester) async {
    final user = storeUser(role: 'admin');
    final auth = StoreAuthFake()
      ..activeSession = storeSession(user)
      ..verifiedUser = user;
    final client = StoreClientFake(auth);
    await tester.pumpWidget(
        MaterialApp(home: LoginRegisterScreen(access: AdminAccess(client))));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'synthetic@example.test');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'synthetic password');
    await tester.ensureVisible(find.text('CONTINUE'));
    await tester.tap(find.text('CONTINUE'));
    // Lottie loops on the outgoing login route until the route transition ends.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboard), findsOneWidget);
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(auth.verifyCalls, greaterThanOrEqualTo(2));
    await tester.pumpWidget(const SizedBox.shrink());
    await auth.events.close();
  });
}
