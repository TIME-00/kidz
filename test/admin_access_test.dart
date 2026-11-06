import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidz_store/admin_access.dart';
import 'package:kidz_store/admin_dashboard.dart';
import 'package:kidz_store/manage_users.dart';
import 'package:kidz_store/manage_sellers.dart';
import 'package:kidz_store/manage_products.dart';
import 'package:kidz_store/manage_orders.dart';
import 'package:kidz_store/session_routing.dart';

import 'support/auth_fakes.dart';

void main() {
  late StoreAuthFake auth;
  late StoreClientFake client;
  late AdminAccess access;
  setUp(() {
    auth = StoreAuthFake();
    client = StoreClientFake(auth);
    access = AdminAccess(client);
  });
  tearDown(() async => auth.events.close());

  void signedIn(User user) {
    auth.activeSession = storeSession(user);
    auth.verifiedUser = user;
  }

  test('only exact server app_metadata role grants Admin', () {
    expect(hasAdminRole(null), isFalse);
    for (final role in [
      null,
      true,
      'Admin',
      ['admin'],
      {'role': 'admin'}
    ]) {
      expect(hasAdminRole(storeUser(role: role, userRole: 'admin')), isFalse);
    }
    expect(hasAdminRole(storeUser(role: 'admin')), isTrue);
  });

  test('missing or expired session cannot authorize or call getUser', () async {
    expect(await access.verifyAdmin(), isFalse);
    auth.activeSession = storeSession(storeUser(role: 'admin'),
        lifetime: const Duration(seconds: -1));
    expect(await access.verifyAdmin(), isFalse);
    expect(auth.verifyCalls, 0);
  });

  test('server result overrides a cached Admin role', () async {
    auth.activeSession = storeSession(storeUser(role: 'admin'));
    auth.verifiedUser = storeUser();
    expect(await access.verifyAdmin(), isFalse);
  });

  test('identity changes during verification are rejected', () async {
    signedIn(storeUser(role: 'admin'));
    final pending = Completer<UserResponse>();
    auth.onVerify = () => pending.future;
    final result = access.verifyAdmin();
    auth.activeSession = storeSession(storeUser(id: 'another-user'));
    pending.complete(UserResponse.fromJson(storeUser(role: 'admin').toJson()));
    expect(await result, isFalse);
  });

  test('Admin, Buyer and Seller Auth destinations preserve the shared home',
      () async {
    for (final role in ['admin', 'buyer', 'seller', null]) {
      signedIn(storeUser(role: role));
      await access.signIn(
          email: 'synthetic@example.test', password: ' synthetic ');
      expect(await verifiedDestinationFor(access),
          role == 'admin' ? StartupDestination.admin : StartupDestination.home);
      expect(auth.submittedPassword, ' synthetic ');
    }
    expect(client.reads, isEmpty,
        reason: 'Auth must never query legacy credentials');
  });

  test('Buyer and Seller restoration retains offline Home entry', () async {
    for (final role in [null, 'buyer', 'seller']) {
      signedIn(storeUser(role: role));
      auth.verifyError = const AuthException('offline');
      expect(await verifiedDestinationFor(access), StartupDestination.home);
    }
    expect(auth.verifyCalls, 0);
  });

  test('verification failures cannot restore a privileged session', () async {
    signedIn(storeUser(role: 'admin'));
    auth.verifyError = const AuthException('synthetic failure');
    expect(await verifiedDestinationFor(access), StartupDestination.login);
  });

  final screens = <String, Widget Function(AdminAccess)>{
    'dashboard': (a) => AdminDashboard(access: a),
    'users': (a) => ManageUsersScreen(access: a),
    'sellers': (a) => ManageSellers(access: a),
    'products': (a) => ManageProducts(access: a),
    'orders': (a) => ManageOrders(access: a),
  };
  for (final entry in screens.entries) {
    for (final role in ['guest', 'buyer', 'seller', 'spoofed', 'error']) {
      testWidgets(
          '${entry.key} rejects direct navigation by $role before querying',
          (tester) async {
        if (role != 'guest') signedIn(storeUser(userRole: 'admin'));
        if (role == 'error') auth.verifyError = const AuthException('denied');
        await tester.pumpWidget(MaterialApp(home: entry.value(access)));
        await tester.pumpAndSettle();
        expect(
            find.text('Admin access could not be verified.'), findsOneWidget);
        expect(client.reads, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
      'gate removes protected data after logout and ignores a stale request',
      (tester) async {
    signedIn(storeUser(role: 'admin'));
    final pending = Completer<UserResponse>();
    auth.onVerify = () => pending.future;
    await tester.pumpWidget(MaterialApp(
        home: AdminGate(
            access: access, builder: (_) => const Text('Protected data'))));
    await tester.pump();
    await access.signOut();
    auth.onVerify = null;
    pending.complete(UserResponse.fromJson(storeUser(role: 'admin').toJson()));
    await tester.pumpAndSettle();
    expect(find.text('Protected data'), findsNothing);
    expect(find.text('Admin access could not be verified.'), findsOneWidget);
  });

  testWidgets('role demotion on auth event hides protected data',
      (tester) async {
    signedIn(storeUser(role: 'admin'));
    await tester.pumpWidget(MaterialApp(
        home: AdminGate(
            access: access, builder: (_) => const Text('Protected data'))));
    await tester.pumpAndSettle();
    expect(find.text('Protected data'), findsOneWidget);
    auth.verifiedUser = storeUser();
    auth.events
        .add(AuthState(AuthChangeEvent.tokenRefreshed, auth.activeSession));
    await tester.pumpAndSettle();
    expect(find.text('Protected data'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Admin dashboard uses exact totals beyond the REST row limit',
      (tester) async {
    signedIn(storeUser(role: 'admin'));
    client.counts.addAll(
        {'users': 1501, 'sellers': 1200, 'products': 2345, 'orders': 9999});
    await tester.pumpWidget(MaterialApp(home: AdminDashboard(access: access)));
    await tester.pumpAndSettle();
    expect(client.reads.toSet(),
        {'users:count', 'sellers:count', 'products:count', 'orders:count'});
    expect(find.text('1501'), findsOneWidget);
    expect(find.text('9999'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Users tolerate a bare Auth-created profile; delete is available',
      (tester) async {
    signedIn(storeUser(role: 'admin'));
    client.rows['users'] = [
      {
        'id': 'fixture',
        'first_name': null,
        'last_name': null,
        'email': 'synthetic@example.test',
        'mobile_number': '0123'
      }
    ];
    await tester
        .pumpWidget(MaterialApp(home: ManageUsersScreen(access: access)));
    await tester.pumpAndSettle();
    expect(find.text('User'), findsOneWidget);
    expect(find.textContaining('0123'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
        isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Products preserve the original delete action', (tester) async {
    signedIn(storeUser(role: 'admin'));
    client.rows['products'] = [
      {
        'id': 'fixture',
        'product_name': 'Fixture product',
        'product_price': 12,
        'product_images': <String>[]
      }
    ];
    await tester.pumpWidget(MaterialApp(home: ManageProducts(access: access)));
    await tester.pumpAndSettle();
    expect(find.text('Fixture product'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
        isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Orders preserve the actual stored status with management enabled',
      (tester) async {
    signedIn(storeUser(role: 'admin'));
    client.rows['orders'] = [
      {
        'id': 'fixture',
        'order_date': null,
        'status': 'Completed',
        'total_price': 12
      }
    ];
    await tester.pumpWidget(MaterialApp(home: ManageOrders(access: access)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Status: Completed'), findsOneWidget);
    expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .onChanged,
        isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('empty and failed Admin reads are distinct and retryable',
      (tester) async {
    signedIn(storeUser(role: 'admin'));
    client.failReads = true;
    await tester.pumpWidget(MaterialApp(home: ManageSellers(access: access)));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load Admin data.'), findsOneWidget);
    client.failReads = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No records found.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('an unconfirmed account cannot restore a session', () async {
    signedIn(storeUser(role: 'admin', confirmed: false));
    expect(await verifiedDestinationFor(access), StartupDestination.login);
  });

  testWidgets('session expiry removes protected content without an Auth event',
      (tester) async {
    final admin = storeUser(role: 'admin');
    auth.activeSession =
        storeSession(admin, lifetime: const Duration(minutes: 2));
    auth.verifiedUser = admin;
    await tester.pumpWidget(MaterialApp(
        home: AdminGate(
            access: access, builder: (_) => const Text('Protected data'))));
    await tester.pumpAndSettle();
    expect(find.text('Protected data'), findsOneWidget);
    await tester.pump(const Duration(minutes: 3));
    expect(find.text('Protected data'), findsNothing);
  });

  testWidgets('resuming the application rechecks the current server role',
      (tester) async {
    signedIn(storeUser(role: 'admin'));
    await tester.pumpWidget(MaterialApp(
        home: AdminGate(
            access: access, builder: (_) => const Text('Protected data'))));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    auth.verifiedUser = storeUser();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Protected data'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Admin logout clears navigation back to protected screens',
      (tester) async {
    signedIn(storeUser(role: 'admin'));
    await tester.pumpWidget(MaterialApp(home: AdminDashboard(access: access)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(auth.activeSession, isNull);
    expect(find.byType(AdminDashboard), findsNothing);
    expect(find.text('Login / Register'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
