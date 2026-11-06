import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidz_store/admin_access.dart';
import 'package:kidz_store/admin_management.dart';
import 'package:kidz_store/manage_users.dart';
import 'package:kidz_store/manage_products.dart';
import 'package:kidz_store/manage_orders.dart';

import 'support/auth_fakes.dart';

const recordId = '20000000-0000-4000-8000-000000000001';
const version = '2026-11-01T00:00:00Z';

void main() {
  late StoreAuthFake auth;
  late StoreClientFake client;
  late AdminManagement management;
  setUp(() {
    final admin = storeUser(role: 'admin');
    auth = StoreAuthFake()
      ..activeSession = storeSession(admin)
      ..verifiedUser = admin;
    client = StoreClientFake(auth);
    management = AdminManagement(AdminAccess(client));
    client.onRpc = (name, params) => name == 'admin_preview_delete'
        ? {
            'id': recordId,
            'kind': params['p_kind'],
            'label': 'Synthetic target',
            'token': 'synthetic-preview',
            'cart_rows_deleted': 2,
            'products_deleted': 1,
            'orders_retained': 3,
            'images_retained': 1,
            'cards_deleted': 1,
            'sellers_deleted': 1
          }
        : name == 'admin_delete_record'
            ? {'deleted': true, 'id': recordId, 'kind': params['p_kind']}
            : {
                'id': recordId,
                'status': params['p_status'],
                'updated_at': version
              };
  });
  tearDown(() async => auth.events.close());

  for (final role in ['guest', 'buyer', 'seller', 'spoofed', 'demoted']) {
    test('$role cannot invoke Admin mutation APIs from the client service',
        () async {
      auth.verifiedUser =
          storeUser(role: role == 'demoted' ? null : role, userRole: 'admin');
      if (role == 'guest') auth.activeSession = null;
      expect(() => management.previewDelete('user', recordId),
          throwsA(isA<AdminOperationException>()));
      expect(
          () => management.deleteRecord('product', recordId, 'token', 'DELETE'),
          throwsA(isA<AdminOperationException>()));
      expect(() => management.setOrderStatus(recordId, 'Shipping', version),
          throwsA(isA<AdminOperationException>()));
      // Await microtasks so all rejected Futures have reached their Auth boundary.
      await Future<void>.delayed(Duration.zero);
      expect(client.rpcCalls, isEmpty);
    });
  }

  test('expired sessions and verification failures cannot mutate', () async {
    auth.activeSession = storeSession(storeUser(role: 'admin'),
        lifetime: const Duration(seconds: -1));
    await expectLater(management.previewDelete('product', recordId),
        throwsA(isA<AdminOperationException>()));
    auth.activeSession = storeSession(storeUser(role: 'admin'));
    auth.verifyError = const AuthException('upstream detail');
    await expectLater(management.previewDelete('product', recordId),
        throwsA(isA<AdminOperationException>()));
    expect(client.rpcCalls, isEmpty);
  });

  test(
      'status API is narrowly bound to ID, allowed status and expected version',
      () async {
    await management.setOrderStatus(recordId, 'Shipping', version);
    expect(client.rpcCalls.single['name'], 'admin_set_order_status');
    expect(client.rpcCalls.single['params'], {
      'p_id': recordId,
      'p_status': 'Shipping',
      'p_expected_updated_at': version
    });
    for (final invalid in ['', 'Completed', 'admin']) {
      await expectLater(management.setOrderStatus(recordId, invalid, version),
          throwsA(isA<AdminOperationException>()));
    }
    expect(client.rpcCalls.length, 1);
  });

  test('delete requires exact confirmation and binds target plus preview token',
      () async {
    await expectLater(
        management.deleteRecord('user', recordId, 'token', 'delete'),
        throwsA(isA<AdminOperationException>()));
    expect(client.rpcCalls, isEmpty);
    await management.deleteRecord(
        'user', recordId, 'synthetic-preview', 'DELETE');
    expect(client.rpcCalls.single['params'], {
      'p_kind': 'user',
      'p_id': recordId,
      'p_token': 'synthetic-preview',
      'p_confirmation': 'DELETE'
    });
  });

  for (final code in [
    '42501',
    '40001',
    'PT409',
    'P0002',
    'PT404',
    '23514',
    '22023',
    '55P03',
    'XX000'
  ]) {
    test(
        'server $code is handled without leaking raw error details or retrying',
        () async {
      client.onRpc = (_, __) => throw PostgrestException(
          message: 'private upstream detail', code: code);
      try {
        await management.previewDelete('user', recordId);
        fail('expected failure');
      } on AdminOperationException catch (error) {
        expect(error.message, isNot(contains('private upstream detail')));
      }
      expect(client.rpcCalls.length, 1);
    });
  }

  test('a mismatched mutation response cannot be reported as success',
      () async {
    client.onRpc = (_, __) => {'deleted': true, 'id': 'wrong', 'kind': 'user'};
    await expectLater(
        management.deleteRecord('user', recordId, 'token', 'DELETE'),
        throwsA(isA<AdminOperationException>()));
  });

  test('Admin lists paginate beyond the REST result cap', () async {
    client.rows['users'] = List.generate(1201, (i) => {'id': i.toString()});
    final rows = await readAdminRows(client, 'users', 'id');
    expect(rows.length, 1201);
    expect(rows.last['id'], '1200');
    expect(client.reads.length, 3);
  });

  Future<void> mountProduct(WidgetTester tester) async {
    client.rows['products'] = [
      {
        'id': recordId,
        'product_name': 'Synthetic product',
        'product_price': 12,
        'product_images': <String>[]
      }
    ];
    await tester.pumpWidget(
        MaterialApp(home: ManageProducts(access: AdminAccess(client))));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'product deletion discloses effects, requires typing, and refreshes',
      (tester) async {
    final original = client.onRpc!;
    client.onRpc = (name, params) {
      if (name == 'admin_delete_record') client.rows['products'] = [];
      return original(name, params);
    };
    await mountProduct(tester);
    await tester.tap(find.byTooltip('Delete product'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Cart entries removed (including other buyers): 2'),
        findsOneWidget);
    expect(find.text('Order history and stored images will be retained.'),
        findsOneWidget);
    final button = find.widgetWithText(TextButton, 'Delete');
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('No records found.'), findsOneWidget);
    expect(client.rpcCalls.map((call) => call['name']),
        ['admin_preview_delete', 'admin_delete_record']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cancelled deletion performs no mutation', (tester) async {
    await mountProduct(tester);
    await tester.tap(find.byTooltip('Delete product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(client.rpcCalls.length, 1);
    expect(find.text('Synthetic product'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'deletion preview rejects a mismatched target before confirmation',
      (tester) async {
    client.onRpc =
        (_, __) => {'id': 'wrong', 'kind': 'product', 'token': 'synthetic'};
    await mountProduct(tester);
    await tester.tap(find.byTooltip('Delete product'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Unable to verify deletion effects'),
        findsOneWidget);
    expect(client.rpcCalls.length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('user deletion describes Auth removal and retained order history',
      (tester) async {
    client.rows['users'] = [
      {'id': recordId, 'email': 'synthetic@example.test'}
    ];
    final original = client.onRpc!;
    client.onRpc = (name, params) {
      if (name == 'admin_delete_record') client.rows['users'] = [];
      return original(name, params);
    };
    await tester.pumpWidget(
        MaterialApp(home: ManageUsersScreen(access: AdminAccess(client))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete user'));
    await tester.pumpAndSettle();
    expect(find.text('This permanently deletes the Auth account and profile.'),
        findsOneWidget);
    expect(
        find.textContaining('Orders retained without the deleted account: 3'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No records found.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('role removal during confirmation prevents the pending mutation',
      (tester) async {
    await mountProduct(tester);
    await tester.tap(find.byTooltip('Delete product'));
    await tester.pumpAndSettle();
    auth.verifiedUser = storeUser();
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(client.rpcCalls.length, 1);
    expect(find.text('Synthetic product'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'order dropdown invokes server update then shows confirmed status',
      (tester) async {
    client.rows['orders'] = [
      {
        'id': recordId,
        'status': 'Packaging',
        'updated_at': version,
        'total_price': 12
      }
    ];
    final original = client.onRpc!;
    client.onRpc = (name, params) {
      client.rows['orders']!.single['status'] = params['p_status'];
      return original(name, params);
    };
    await tester.pumpWidget(
        MaterialApp(home: ManageOrders(access: AdminAccess(client))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shipping').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Status: Shipping'), findsOneWidget);
    expect(client.rpcCalls.single['name'], 'admin_set_order_status');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('order conflict does not optimistically change displayed status',
      (tester) async {
    client.rows['orders'] = [
      {
        'id': recordId,
        'status': 'Packaging',
        'updated_at': version,
        'total_price': 12
      }
    ];
    client.onRpc = (_, __) =>
        throw const PostgrestException(message: 'internal', code: '40001');
    await tester.pumpWidget(
        MaterialApp(home: ManageOrders(access: AdminAccess(client))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shipping').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Status: Packaging'), findsOneWidget);
    expect(find.textContaining('changed. Refresh'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
