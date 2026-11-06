import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generates only the sales report for the current user (as a seller)
Future<Map<String, dynamic>> generateAllInvolvingMeReport({
  required String reportType,
  required String selectedDate,
  required String myUserId,
}) async {
  final supabase = Supabase.instance.client;

  DateTime startTime;
  DateTime endTime;
  if (reportType == "daily") {
    startTime = DateTime.parse("$selectedDate 00:00:00");
    endTime = DateTime.parse("$selectedDate 23:59:59");
  } else if (reportType == "monthly") {
    final parts = selectedDate.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    startTime = DateTime(year, month, 1, 0, 0, 0);
    endTime = DateTime(year, month + 1, 1, 0, 0, 0)
        .subtract(const Duration(seconds: 1));
  } else if (reportType == "yearly") {
    final year = int.parse(selectedDate);
    startTime = DateTime(year, 1, 1, 0, 0, 0);
    endTime = DateTime(year, 12, 31, 23, 59, 59);
  } else {
    return {};
  }

  final sellersResponse = await supabase.from('sellers').select('id, user_id');

  if (sellersResponse == null || sellersResponse.isEmpty) {
    return _emptySalesReport(reportType);
  }

  final Map<String, String> sellerIdMap = {
    for (final s in sellersResponse) s['id'] as String: s['user_id'] as String
  };

  final productsResponse = await supabase
      .from('products')
      .select('id, product_name, product_price, seller_id');

  if (productsResponse == null || productsResponse.isEmpty) {
    return {"error": "No product data available."};
  }

  final productMap = <String, Map<String, dynamic>>{
    for (final p in productsResponse)
      p['id'] as String: {
        'name': p['product_name'] ?? 'Unknown Product',
        'price': (p['product_price'] ?? 0).toDouble(),
        'seller_id': p['seller_id'] ?? '',
      },
  };

  final ordersResponse = await supabase
      .from('orders')
      .select('order_date, total_price, order_items, user_id')
      .gte('order_date', startTime.toIso8601String())
      .lte('order_date', endTime.toIso8601String());

  if (ordersResponse == null || ordersResponse.isEmpty) {
    return _emptySalesReport(reportType);
  }

  double totalSales = 0.0;
  final Map<String, dynamic> salesMap = {};

  for (final order in ordersResponse) {
    final orderItemsJson = order['order_items'] as String?;
    if (orderItemsJson == null || orderItemsJson.isEmpty) continue;
    List<dynamic> orderItems;
    try {
      orderItems = jsonDecode(orderItemsJson);
    } catch (e) {
      continue;
    }

    for (final item in orderItems) {
      final pid = item['product_id'] as String?;
      final qty = (item['quantity'] ?? 0) as int;
      if (pid == null || !productMap.containsKey(pid)) continue;

      final productInfo = productMap[pid]!;
      final productName = productInfo['name'] as String;
      final productPrice = productInfo['price'] as double;
      final sellerId = productInfo['seller_id'] as String;
      final itemTotalPrice = productPrice * qty;

      final isMyProduct = (sellerIdMap.containsKey(sellerId) &&
          sellerIdMap[sellerId] == myUserId);
      if (isMyProduct) {
        if (salesMap.containsKey(productName)) {
          salesMap[productName]['Quantity Sold'] += qty;
          salesMap[productName]['Total Price'] += itemTotalPrice;
        } else {
          salesMap[productName] = {
            'Individual Price': productPrice,
            'Quantity Sold': qty,
            'Total Price': itemTotalPrice,
          };
        }
        totalSales += itemTotalPrice;
      }
    }
  }

  salesMap['Total Sales'] = totalSales;

  final keyName = reportType == "daily"
      ? "Daily Involving Me"
      : reportType == "monthly"
          ? "Monthly Involving Me"
          : "Yearly Involving Me";

  return {
    keyName: {
      "Sales": salesMap,
    },
  };
}

Map<String, dynamic> _emptySalesReport(String reportType) {
  final keyName = reportType == "daily"
      ? "Daily Involving Me"
      : reportType == "monthly"
          ? "Monthly Involving Me"
          : "Yearly Involving Me";

  return {
    keyName: {
      "Sales": {"Total Sales": 0.0},
    },
  };
}

Future<List<Map<String, dynamic>>> fetchTop10BestSellers({
  required String myUserId,
}) async {
  final supabase = Supabase.instance.client;

  final sellersResponse = await supabase.from('sellers').select('id, user_id');
  if (sellersResponse == null || sellersResponse.isEmpty) return [];

  final sellerIdMap = {
    for (final s in sellersResponse) s['id'] as String: s['user_id'] as String
  };

  final productsResponse = await supabase
      .from('products')
      .select('id, product_name, product_price, seller_id');
  if (productsResponse == null || productsResponse.isEmpty) return [];

  final productMap = {
    for (final p in productsResponse)
      p['id'] as String: {
        'name': p['product_name'] ?? 'Unknown Product',
        'price': (p['product_price'] ?? 0).toDouble(),
        'seller_id': p['seller_id'] ?? '',
      },
  };

  final ordersResponse = await supabase.from('orders').select('order_items');
  if (ordersResponse == null || ordersResponse.isEmpty) return [];

  final productCount = <String, int>{};

  for (final order in ordersResponse) {
    final orderItemsJson = order['order_items'] as String?;
    if (orderItemsJson == null || orderItemsJson.isEmpty) continue;
    List<dynamic> orderItems;
    try {
      orderItems = jsonDecode(orderItemsJson);
    } catch (e) {
      continue;
    }

    for (final item in orderItems) {
      final pid = item['product_id'] as String?;
      final qty = (item['quantity'] ?? 0) as int;
      if (pid == null || !productMap.containsKey(pid)) continue;

      final sellerId = productMap[pid]!['seller_id'] as String;
      if (sellerId == myUserId || (sellerIdMap[sellerId] ?? '') == myUserId) {
        productCount[pid] = (productCount[pid] ?? 0) + qty;
      }
    }
  }

  final sortedEntries = productCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top10 = sortedEntries.take(10).toList();

  return [
    for (final e in top10)
      {
        'product_id': e.key,
        'product_name': productMap[e.key]!['name'],
        'product_price': productMap[e.key]!['price'],
        'quantity_sold': e.value,
      },
  ];
}
