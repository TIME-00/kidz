import 'package:supabase_flutter/supabase_flutter.dart';
import 'seller_orders.dart';

/// Uses original purchase prices, not today's catalogue, and server-owned scope.
Future<Map<String, dynamic>> generateAllInvolvingMeReport({
  required String reportType,
  required String selectedDate,
  required String myUserId,
  SupabaseClient? client,
}) async {
  final dates = sellerReportDates(reportType, selectedDate);
  final orders = await SellerOrders(client ?? Supabase.instance.client)
      .read(expectedUserId: myUserId, start: dates.$1, end: dates.$2);
  return buildSellerSalesReport(orders, reportType);
}

/// Half-open calendar ranges include fractional seconds at the period's end.
(DateTime, DateTime) sellerReportDates(String type, String value) {
  final parts = value.split('-').map(int.parse).toList();
  final year = parts.first;
  if (type == 'yearly') return (DateTime(year), DateTime(year + 1));
  final month = parts[1];
  if (type == 'monthly') {
    return (DateTime(year, month), DateTime(year, month + 1));
  }
  if (type == 'daily') {
    final day = parts[2];
    return (DateTime(year, month, day), DateTime(year, month, day + 1));
  }
  throw const FormatException('Unsupported report period.');
}

Map<String, _ProductSales> _aggregate(List<Map<String, dynamic>> orders) {
  final sales = <String, _ProductSales>{};
  for (final order in orders) {
    for (final item in decodeSellerItems(order['order_items'])) {
      final id = item['product_id'] as String;
      final quantity = sellerItemQuantity(item);
      final cents = sellerItemCents(item);
      final product = sales.putIfAbsent(
          id,
          () => _ProductSales(
              id, item['product_name'] as String? ?? 'Unknown Product', cents));
      product.quantity += quantity;
      product.totalCents += cents * quantity;
      product.prices.add(cents);
      if (product.totalCents > 9007199254740991) {
        throw const FormatException('Sales total exceeds supported precision.');
      }
    }
  }
  return sales;
}

Map<String, dynamic> buildSellerSalesReport(
    List<Map<String, dynamic>> orders, String type) {
  final products = _aggregate(orders).values.toList();
  final names = <String, int>{};
  for (final product in products) {
    names[product.name] = (names[product.name] ?? 0) + 1;
  }
  final sales = <String, dynamic>{};
  var totalCents = 0;
  for (final product in products) {
    final label = names[product.name]! > 1 || product.name == 'Total Sales'
        ? '${product.name} (${product.id})'
        : product.name;
    sales[label] = {
      'Individual Price':
          product.prices.length == 1 ? product.latestCents / 100 : 'Varies',
      'Quantity Sold': product.quantity,
      'Total Price': product.totalCents / 100,
    };
    totalCents += product.totalCents;
    if (totalCents > 9007199254740991) {
      throw const FormatException('Sales total exceeds supported precision.');
    }
  }
  sales['Total Sales'] = totalCents / 100;
  final title = type == 'daily'
      ? 'Daily'
      : type == 'monthly'
          ? 'Monthly'
          : 'Yearly';
  return {
    '$title Involving Me': {'Sales': sales}
  };
}

Future<List<Map<String, dynamic>>> fetchTop10BestSellers({
  required String myUserId,
  SupabaseClient? client,
}) async {
  final orders = await SellerOrders(client ?? Supabase.instance.client)
      .read(expectedUserId: myUserId);
  return buildSellerTop10(orders);
}

List<Map<String, dynamic>> buildSellerTop10(List<Map<String, dynamic>> orders) {
  final products = _aggregate(orders).values.toList()
    ..sort((a, b) {
      final count = b.quantity.compareTo(a.quantity);
      return count != 0 ? count : a.id.compareTo(b.id);
    });
  return products
      .take(10)
      .map((product) => <String, dynamic>{
            'product_id': product.id,
            'product_name': product.name,
            'product_price': product.latestCents / 100,
            'quantity_sold': product.quantity,
          })
      .toList();
}

class _ProductSales {
  _ProductSales(this.id, this.name, this.latestCents);
  final String id;
  final String name;
  final int latestCents;
  final prices = <int>{};
  int quantity = 0;
  int totalCents = 0;
}
