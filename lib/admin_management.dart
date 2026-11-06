import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_access.dart';

const adminOrderStatuses = ['Packaging', 'Shipping', 'Delivering'];

class AdminOperationException implements Exception {
  const AdminOperationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A client convenience layer, never the authority. Each narrow RPC independently
/// validates the signed identity, current server role and live Auth session.
class AdminManagement {
  AdminManagement(this.access);
  final AdminAccess access;

  Future<Map<String, dynamic>> _call(
      String name, Map<String, dynamic> params) async {
    try {
      if (!await access.verifyAdmin()) {
        throw const AdminOperationException(
            'Sign in with an Admin account again.');
      }
      final response = await access.client.rpc(name, params: params);
      return Map<String, dynamic>.from(response as Map);
    } on AdminOperationException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AdminOperationException(switch (error.code) {
        '42501' =>
          'This action is not allowed. Admin accounts are protected; verify your Admin session.',
        '40001' ||
        'PT409' =>
          'The record or deletion effects changed. Refresh and confirm again.',
        'P0002' || 'PT404' => 'The record no longer exists. Refresh the list.',
        '23514' =>
          'The account owns storage outside product-images. Review its ownership before deletion.',
        '22023' => 'The action or confirmation is invalid.',
        '55P03' || '57014' => 'The record is busy. Refresh and try again.',
        _ =>
          'Unable to complete the Admin action. Check the server setup and try again.',
      });
    } catch (_) {
      throw const AdminOperationException(
          'Unable to verify or complete the Admin action. Try again.');
    }
  }

  Future<Map<String, dynamic>> previewDelete(String kind, String id) =>
      _call('admin_preview_delete', {'p_kind': kind, 'p_id': id});

  Future<void> deleteRecord(
      String kind, String id, String token, String confirmation) async {
    if (confirmation != 'DELETE') {
      throw const AdminOperationException('Type DELETE to confirm.');
    }
    final result = await _call('admin_delete_record', {
      'p_kind': kind,
      'p_id': id,
      'p_token': token,
      'p_confirmation': confirmation,
    });
    if (result['deleted'] != true ||
        result['id'] != id ||
        result['kind'] != kind) {
      throw const AdminOperationException(
          'Deletion was not confirmed by the server. Refresh before trying again.');
    }
  }

  Future<void> setOrderStatus(
      String id, String status, String expectedUpdatedAt) async {
    if (!adminOrderStatuses.contains(status)) {
      throw const AdminOperationException('Unsupported order status.');
    }
    final result = await _call('admin_set_order_status', {
      'p_id': id,
      'p_status': status,
      'p_expected_updated_at': expectedUpdatedAt,
    });
    if (result['id'] != id || result['status'] != status) {
      throw const AdminOperationException(
          'The update was not confirmed by the server. Refresh the list.');
    }
  }
}

/// Stable primary-key paging keeps Admin lists from silently stopping at the
/// REST row limit. RLS still applies to every page.
Future<List<Map<String, dynamic>>> readAdminRows(
    SupabaseClient client, String table, String columns) async {
  const size = 500;
  final result = <Map<String, dynamic>>[];
  for (var offset = 0;; offset += size) {
    final page = await client
        .from(table)
        .select(columns)
        .order('id')
        .range(offset, offset + size - 1);
    result.addAll(page);
    if (page.length < size) return result;
  }
}

Future<bool> confirmAdminDeletion(BuildContext context,
    AdminManagement management, String kind, String id) async {
  try {
    final preview = await management.previewDelete(kind, id);
    if (!context.mounted) return false;
    // Bind the confirmation to the exact server preview, never a caller label.
    if (preview['kind'] != kind ||
        preview['id'] != id ||
        preview['token'] is! String) {
      throw const AdminOperationException(
          'Unable to verify deletion effects. Refresh the list.');
    }
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _DeleteConfirmation(kind: kind, preview: preview));
    if (confirmed != true || !context.mounted) return false;
    await management.deleteRecord(
        kind, id, preview['token'] as String, 'DELETE');
    return true;
  } on AdminOperationException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
}

class _DeleteConfirmation extends StatefulWidget {
  const _DeleteConfirmation({required this.kind, required this.preview});
  final String kind;
  final Map<String, dynamic> preview;
  @override
  State<_DeleteConfirmation> createState() => _DeleteConfirmationState();
}

class _DeleteConfirmationState extends State<_DeleteConfirmation> {
  String _confirmation = '';
  @override
  Widget build(BuildContext context) {
    final p = widget.preview;
    return AlertDialog(
      title: Text(
          widget.kind == 'user' ? 'Delete user account?' : 'Delete product?'),
      content: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('${p['label'] ?? p['id']}'),
            if (widget.kind == 'user') ...[
              const Text(
                  'This permanently deletes the Auth account and profile.'),
              Text('Seller registrations deleted: ${p['sellers_deleted']}'),
              Text('Saved cards deleted: ${p['cards_deleted']}'),
              Text(
                  'Orders retained without the deleted account: ${p['orders_retained']}'),
              Text(
                  'Stored images retained under Admin ownership: ${p['images_retained']}'),
            ] else
              const Text('Order history and stored images will be retained.'),
            Text('Products deleted: ${p['products_deleted']}'),
            Text(
                'Cart entries removed (including other buyers): ${p['cart_rows_deleted']}'),
            const Text('This cannot be undone. Type DELETE to confirm.'),
            TextField(
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Confirmation'),
                onChanged: (value) => setState(() => _confirmation = value)),
          ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: _confirmation == 'DELETE'
                ? () => Navigator.pop(context, true)
                : null,
            child: const Text('Delete')),
      ],
    );
  }
}
