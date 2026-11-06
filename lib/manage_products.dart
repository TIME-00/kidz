import 'package:flutter/material.dart';
import 'admin_access.dart';
import 'admin_management.dart';
import 'product_image.dart';

class ManageProducts extends StatelessWidget {
  const ManageProducts({super.key, this.access});
  final AdminAccess? access;
  @override
  Widget build(BuildContext context) => AdminGate(
        access: access,
        builder: (access) => _ManageProductsBody(access: access),
      );
}

class _ManageProductsBody extends StatefulWidget {
  const _ManageProductsBody({required this.access});
  final AdminAccess access;
  @override
  State<_ManageProductsBody> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<_ManageProductsBody> {
  late final _supabase = widget.access.client;
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  bool _mutating = false;
  late final _management = AdminManagement(widget.access);

  Future<void> _deleteRecord(String id) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      final deleted =
          await confirmAdminDeletion(context, _management, 'product', id);
      if (deleted && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Product deleted.')));
        await fetchProducts();
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  bool _loading = true;
  bool _failed = false;

  Future<void> fetchProducts() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await readAdminRows(_supabase, 'products',
          'id, product_name, product_price, product_images, seller_id');
      if (!mounted) return;
      setState(() => products = List<Map<String, dynamic>>.from(response));
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
          title: const Text("Manage Products"), backgroundColor: Colors.orange),
      body: AdminReadState(
        loading: _loading,
        failed: _failed,
        empty: products.isEmpty,
        onRetry: fetchProducts,
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final String? imageUrl =
                firstProductImageUrl(product['product_images']);

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: productImage(imageUrl,
                    width: 50, height: 50, fit: BoxFit.cover),
                title: Text(product['product_name']),
                subtitle: Text("Price: RM ${product['product_price']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _mutating
                      ? null
                      : () => _deleteRecord(product['id'] as String),
                  tooltip: 'Delete product',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
