import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Only the server's redacted projection is consumed; never select raw orders.
class SellerOrders {
  SellerOrders(this.client, {this.pageSize = 200});
  final SupabaseClient client;
  final int pageSize;

  Future<List<Map<String, dynamic>>> read({
    String? expectedUserId,
    DateTime? start,
    DateTime? end,
  }) async {
    final session = client.auth.currentSession;
    if (session == null ||
        session.isExpired ||
        (expectedUserId != null && session.user.id != expectedUserId)) {
      throw const AuthException('Seller sign-in required.');
    }
    final result = <Map<String, dynamic>>[];
    String? beforeDate;
    String? beforeId;
    while (true) {
      final response = await client.rpc('seller_order_page', params: {
        'p_start': start?.toUtc().toIso8601String(),
        'p_end': end?.toUtc().toIso8601String(),
        'p_before_date': beforeDate,
        'p_before_id': beforeId,
        'p_limit': pageSize,
      });
      if (response is! Map || response['orders'] is! List) {
        throw const FormatException('Invalid Seller order response.');
      }
      final page = (response['orders'] as List).map((value) {
        final row = Map<String, dynamic>.from(value as Map);
        row['order_items'] = decodeSellerItems(row['order_items']);
        return row;
      }).toList();
      result.addAll(page);
      if (page.length < pageSize) return result;
      final nextDate = page.last['order_date'] as String;
      final nextId = page.last['id'] as String;
      if (nextDate == beforeDate && nextId == beforeId) {
        throw const FormatException('Invalid Seller order cursor.');
      }
      beforeDate = nextDate;
      beforeId = nextId;
    }
  }

  Future<void> setStatus(Map<String, dynamic> order, String status) async {
    if (order['can_update_status'] != true) {
      throw const AuthException('This order status is managed by Admin.');
    }
    await client.rpc('seller_set_order_status', params: {
      'p_id': order['id'],
      'p_status': status,
      'p_expected_updated_at': order['updated_at'],
    });
  }
}

List<Map<String, dynamic>> decodeSellerItems(dynamic value) {
  final decoded = value is String ? jsonDecode(value) : value;
  if (decoded is! List) {
    throw const FormatException('Invalid Seller order items.');
  }
  return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

int sellerItemQuantity(Map<String, dynamic> item) {
  final value = item['quantity'];
  if (value is! int || value <= 0) {
    throw const FormatException('An order has an invalid purchase quantity.');
  }
  return value;
}

int sellerItemCents(Map<String, dynamic> item) {
  final value = item['price_cents'];
  if (value is! int || value < 0) {
    throw const FormatException('An order is missing a valid purchase price.');
  }
  return value;
}
