import 'package:flutter/material.dart';
import 'admin_access.dart';
import 'admin_management.dart';
import 'display_name.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key, this.access});
  final AdminAccess? access;
  @override
  Widget build(BuildContext context) => AdminGate(
        access: access,
        builder: (access) => _ManageUsersScreenBody(access: access),
      );
}

class _ManageUsersScreenBody extends StatefulWidget {
  const _ManageUsersScreenBody({required this.access});
  final AdminAccess access;
  @override
  State<_ManageUsersScreenBody> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<_ManageUsersScreenBody> {
  late final supabase = widget.access.client;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  bool _mutating = false;
  late final _management = AdminManagement(widget.access);

  Future<void> _deleteRecord(String id) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      final deleted =
          await confirmAdminDeletion(context, _management, 'user', id);
      if (deleted && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User deleted.')));
        await fetchUsers();
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  bool _loading = true;
  bool _failed = false;

  Future<void> fetchUsers() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await readAdminRows(
          supabase, 'users', 'id, first_name, last_name, email, mobile_number');
      if (!mounted) return;
      setState(() => users = List<Map<String, dynamic>>.from(response));
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
          title: const Text("Manage Users"), backgroundColor: Colors.orange),
      body: AdminReadState(
        loading: _loading,
        failed: _failed,
        empty: users.isEmpty,
        onRetry: fetchUsers,
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(displayName(user["first_name"], user["last_name"])),
                subtitle: Text(
                    "Email: ${user["email"]}\nPhone: ${user["mobile_number"] ?? ""}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _mutating
                      ? null
                      : () => _deleteRecord(user['id'] as String),
                  tooltip: 'Delete user',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
