import 'package:flutter/material.dart';
import 'admin_access.dart';
import 'admin_management.dart';

class ManageOrders extends StatelessWidget {
  const ManageOrders({super.key, this.access});
  final AdminAccess? access;
  @override
  Widget build(BuildContext context) => AdminGate(
        access: access,
        builder: (access) => _ManageOrdersBody(access: access),
      );
}

class _ManageOrdersBody extends StatefulWidget {
  const _ManageOrdersBody({required this.access});
  final AdminAccess access;
  @override
  State<_ManageOrdersBody> createState() => _ManageOrdersState();
}

class _ManageOrdersState extends State<_ManageOrdersBody> {
  late final _supabase = widget.access.client;
  List<dynamic> orders = [];

  final List<String> orderStatuses = adminOrderStatuses;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  bool _mutating = false;
  late final _management = AdminManagement(widget.access);

  Future<void> _updateStatus(Map<String, dynamic> order, String status) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      final version = order['updated_at'];
      if (version is! String) {
        throw const AdminOperationException(
            'Refresh the order before updating it.');
      }
      await _management.setOrderStatus(order['id'] as String, status, version);
      if (mounted) await fetchOrders();
    } on AdminOperationException catch (error) {
      if (mounted) await fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  bool _loading = true;
  bool _failed = false;

  Future<void> fetchOrders() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await readAdminRows(_supabase, 'orders',
          'id, order_date, total_price, status, updated_at');
      if (!mounted) return;
      setState(() => orders = List<Map<String, dynamic>>.from(response));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Manage Orders"), backgroundColor: Colors.orange),
      body: AdminReadState(
        loading: _loading,
        failed: _failed,
        empty: orders.isEmpty,
        onRetry: fetchOrders,
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderDate = (order['order_date'] ?? '')
                .toString()
                .split("T")[0]; // Extract date
            final totalPrice = order['total_price'];

            final String orderStatus = order['status'] ?? 'Unknown';

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text("Order Date: $orderDate"),
                subtitle:
                    Text("Total Price: RM $totalPrice\nStatus: $orderStatus"),
                trailing: DropdownButton<String>(
                  value: orderStatus, // ✅ Default status from database
                  items: {orderStatus, ...orderStatuses}
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: _mutating
                      ? null
                      : (value) {
                          if (value != null && value != orderStatus) {
                            _updateStatus(
                                Map<String, dynamic>.from(order), value);
                          }
                        },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
