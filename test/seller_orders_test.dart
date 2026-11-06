import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidz_store/seller_orders.dart';
import 'package:kidz_store/seller_dashboard.dart';
import 'package:kidz_store/report.dart';
import 'support/auth_fakes.dart';

Map<String, dynamic> item(String id, int cents, int quantity,
        {String name = 'Product'}) =>
    {
      'product_id': id,
      'product_name': name,
      'price_cents': cents,
      'quantity': quantity,
    };
Map<String, dynamic> order(String id, List<Map<String, dynamic>> items,
        {bool allowed = true, String status = 'Packaging'}) =>
    {
      'id': id,
      'order_date': '2026-11-06T10:00:00Z',
      'updated_at': '2026-11-06T10:00:00.123456Z',
      'status': status,
      'order_items': items,
      'can_update_status': allowed,
    };
void main() {
  late StoreAuthFake auth;
  late StoreClientFake client;
  setUp(() {
    auth = StoreAuthFake()..activeSession = storeSession(storeUser());
    client = StoreClientFake(auth);
  });
  tearDown(() async => auth.events.close());
  test(
      'Seller read uses only scoped RPC, follows cursor pages, and binds date range',
      () async {
    var calls = 0;
    client.onRpc = (name, params) {
      expect(name, 'seller_order_page');
      expect(params.containsKey('seller_id'), false);
      expect(params['p_start'], '2026-11-01T00:00:00.000Z');
      expect(params['p_end'], '2026-12-01T00:00:00.000Z');
      calls++;
      if (calls == 1) {
        return {
          'orders': [
            order('b', [item('p', 100, 1)]),
            order('a', [item('p', 100, 1)])
          ]
        };
      }
      expect(params['p_before_id'], 'a');
      return {
        'orders': [
          order('0', [item('p', 100, 1)])
        ]
      };
    };
    final rows = await SellerOrders(client, pageSize: 2)
        .read(start: DateTime.utc(2026, 11), end: DateTime.utc(2026, 12));
    expect(rows.length, 3);
    expect(client.reads, isEmpty);
  });
  test('guest, expired and mismatched-user requests stop before RPC', () async {
    for (final mode in ['guest', 'expired', 'different']) {
      auth.activeSession = mode == 'guest'
          ? null
          : storeSession(storeUser(),
              lifetime: Duration(seconds: mode == 'expired' ? -1 : 3600));
      await expectLater(
          SellerOrders(client)
              .read(expectedUserId: mode == 'different' ? 'other' : null),
          throwsException);
    }
    expect(client.rpcCalls, isEmpty);
  });
  test(
      'mixed/shared status is denied locally and exclusive status sends exact version',
      () async {
    await expectLater(
        SellerOrders(client)
            .setStatus(order('m', [], allowed: false), 'Shipping'),
        throwsException);
    expect(client.rpcCalls, isEmpty);
    client.onRpc = (name, params) => {'id': params['p_id']};
    await SellerOrders(client).setStatus(order('one', []), 'Shipping');
    expect(client.rpcCalls.single, {
      'name': 'seller_set_order_status',
      'params': {
        'p_id': 'one',
        'p_status': 'Shipping',
        'p_expected_updated_at': '2026-11-06T10:00:00.123456Z'
      }
    });
  });
  test(
      'JSONB arrays and encoded arrays decode; malformed shapes do not silently pass',
      () {
    expect(
        decodeSellerItems([
          {'quantity': 2}
        ]),
        [
          {'quantity': 2}
        ]);
    expect(decodeSellerItems('[{"quantity":2}]'), [
      {'quantity': 2}
    ]);
    expect(() => decodeSellerItems('{}'), throwsFormatException);
  });
  for (final type in ['daily', 'monthly', 'yearly']) {
    test(
        '$type sales use purchase cents and every price variant, with original report shape',
        () {
      final report = buildSellerSalesReport([
        order('1', [item('p', 10, 2)]),
        order('2', [item('p', 20, 3)])
      ], type);
      final sales = (report.values.single as Map)['Sales'] as Map;
      expect(sales['Total Sales'], 0.8);
      expect(sales['Product']['Total Price'], 0.8);
      expect(sales['Product']['Quantity Sold'], 5);
      expect(sales['Product']['Individual Price'], 'Varies');
    });
  }
  test('same-name products and the reserved Total Sales label do not collide',
      () {
    final report = buildSellerSalesReport([
      order('1', [
        item('p1', 100, 1, name: 'Total Sales'),
        item('p2', 200, 1),
        item('p3', 300, 1)
      ])
    ], 'daily');
    final sales = (report.values.single as Map)['Sales'] as Map;
    expect(sales.length, 4);
    expect(sales['Total Sales'], 6.0);
    expect(sales.keys,
        containsAll(['Product (p2)', 'Product (p3)', 'Total Sales (p1)']));
  });
  test(
      'missing purchase price and invalid quantity are reported instead of fabricating sales',
      () {
    for (final field in ['price_cents', 'quantity']) {
      final bad = item('p', 100, 1)..[field] = null;
      expect(
          () => buildSellerSalesReport([
                order('1', [bad])
              ], 'daily'),
          throwsFormatException);
    }
  });
  test(
      'Top 10 aggregates by product ID, keeps snapshot price and breaks ties deterministically',
      () {
    final rows = [
      order('1', [
        for (var i = 0; i < 12; i++)
          item('p${i.toString().padLeft(2, '0')}', 1999, 2)
      ])
    ];
    final top = buildSellerTop10(rows);
    expect(top.length, 10);
    expect(top.first['product_id'], 'p00');
    expect(top.first['quantity_sold'], 2);
    expect(top.first['product_price'], 19.99);
  });
  test(
      'calendar bounds include the last fractional second and use the next period exclusively',
      () {
    final day = sellerReportDates('daily', '2026-01-31');
    expect(day.$2, DateTime(2026, 2));
    final month = sellerReportDates('monthly', '2026-12');
    expect(month.$2, DateTime(2027));
    final year = sellerReportDates('yearly', '2026');
    expect(year.$2, DateTime(2027));
    expect(day.$1, DateTime(2026, 1, 31));
  });
  testWidgets(
      'Seller orders preserve dropdown UI, disable mixed orders, and handle stored unknown status',
      (tester) async {
    client.rows['sellers'] = [
      {'id': 'seller', 'user_id': auth.activeSession!.user.id}
    ];
    client.rows['products'] = [];
    client.onRpc = (name, params) => {
          'orders': [
            order('one', [item('p', 100, 1)]),
            order('mixed', [item('p', 100, 1)],
                allowed: false, status: 'Processing')
          ]
        };
    await tester.pumpWidget(MaterialApp(home: SellerDashboard(client: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orders Section'));
    await tester.pumpAndSettle();
    final drops = tester
        .widgetList<DropdownButton<String>>(find.byType(DropdownButton<String>))
        .toList();
    expect(drops.length, 2);
    expect(drops[0].onChanged, isNotNull);
    expect(drops[1].onChanged, isNull);
    expect(find.text('Processing'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
