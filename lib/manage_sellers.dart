import 'package:flutter/material.dart';
import 'admin_access.dart';
import 'admin_management.dart';

class ManageSellers extends StatelessWidget {
  const ManageSellers({super.key, this.access});
  final AdminAccess? access;
  @override
  Widget build(BuildContext context) => AdminGate(
        access: access,
        builder: (access) => _ManageSellersBody(access: access),
      );
}

class _ManageSellersBody extends StatefulWidget {
  const _ManageSellersBody({required this.access});
  final AdminAccess access;
  @override
  State<_ManageSellersBody> createState() => _ManageSellersState();
}

class _ManageSellersState extends State<_ManageSellersBody> {
  late final _supabase = widget.access.client;
  List<dynamic> sellers = [];

  @override
  void initState() {
    super.initState();
    fetchSellers();
  }

  bool _loading = true;
  bool _failed = false;

  Future<void> fetchSellers() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await readAdminRows(
          _supabase, 'sellers', 'id, company_name, ssm_number, product_type');
      if (!mounted) return;
      setState(() => sellers = List<Map<String, dynamic>>.from(response));
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
          title: const Text("Manage Sellers"), backgroundColor: Colors.orange),
      body: AdminReadState(
        loading: _loading,
        failed: _failed,
        empty: sellers.isEmpty,
        onRetry: fetchSellers,
        child: ListView.builder(
          itemCount: sellers.length,
          itemBuilder: (context, index) {
            final seller = sellers[index];
            return Card(
              child: ListTile(
                title: Text(seller['company_name'] ?? ''),
                subtitle: Text(
                    "SSM: ${seller['ssm_number']}\nType: ${seller['product_type']}"),
              ),
            );
          },
        ),
      ),
    );
  }
}
