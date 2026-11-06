import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_access.dart';
import 'login.dart';

import 'manage_orders.dart';
import 'manage_products.dart';
import 'manage_sellers.dart';
import 'manage_users.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, this.access});
  final AdminAccess? access;

  @override
  Widget build(BuildContext context) => AdminGate(
        access: access,
        builder: (access) => _AdminDashboardBody(access: access),
      );
}

class _AdminDashboardBody extends StatefulWidget {
  const _AdminDashboardBody({required this.access});
  final AdminAccess access;

  @override
  State<_AdminDashboardBody> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboardBody> {
  late final supabase = widget.access.client;
  bool _loading = true;
  bool _failed = false;

  int totalUsers = 0;
  int totalSellers = 0;
  int totalProducts = 0;
  int totalOrders = 0;

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }

  Future<void> fetchStatistics() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      // HEAD/count avoids PostgREST's row limit truncating dashboard totals.
      final counts = await Future.wait([
        supabase.from('users').count(CountOption.exact),
        supabase.from('sellers').count(CountOption.exact),
        supabase.from('products').count(CountOption.exact),
        supabase.from('orders').count(CountOption.exact),
      ]);
      if (!mounted) return;
      setState(() {
        totalUsers = counts[0];
        totalSellers = counts[1];
        totalProducts = counts[2];
        totalOrders = counts[3];
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    // Capture Navigator: the gate removes this subtree on the sign-out event.
    final navigator = Navigator.of(context);
    try {
      await widget.access.signOut();
      if (navigator.mounted) {
        navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
            (_) => false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to sign out. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
        actions: [
          IconButton(
              onPressed: _logout,
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ Grid-based layout for buttons
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.4,
              children: [
                _adminButton(
                  label: "Manage Users",
                  icon: Icons.person,
                  onTap: () => _navigateTo(
                      context, ManageUsersScreen(access: widget.access)),
                ),
                _adminButton(
                  label: "Manage Sellers",
                  icon: Icons.store,
                  onTap: () => _navigateTo(
                      context, ManageSellers(access: widget.access)),
                ),
                _adminButton(
                  label: "Manage Products",
                  icon: Icons.shopping_bag,
                  onTap: () => _navigateTo(
                      context, ManageProducts(access: widget.access)),
                ),
                _adminButton(
                  label: "Manage Orders",
                  icon: Icons.shopping_cart,
                  onTap: () =>
                      _navigateTo(context, ManageOrders(access: widget.access)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // ✅ Statistics Section
            AdminReadState(
                loading: _loading,
                failed: _failed,
                empty: false,
                onRetry: fetchStatistics,
                child: _statisticsSection()),
          ],
        ),
      ),
    );
  }

  // ✅ Button for each section
  Widget _adminButton(
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2)
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 35),
            const SizedBox(height: 10),
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ✅ Statistics Section with Chart
  Widget _statisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Statistics Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        // ✅ Statistics Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statsCard("Users", totalUsers, Colors.blue),
            _statsCard("Sellers", totalSellers, Colors.green),
          ],
        ),

        const SizedBox(height: 5),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statsCard("Products", totalProducts, Colors.orange),
            _statsCard("Orders", totalOrders, Colors.red),
          ],
        ),

        const SizedBox(height: 40),

        // ✅ Chart Representation
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              barGroups: [
                _barGroup(0, totalUsers.toDouble(), Colors.blue),
                _barGroup(1, totalSellers.toDouble(), Colors.green),
                _barGroup(2, totalProducts.toDouble(), Colors.orange),
                _barGroup(3, totalOrders.toDouble(), Colors.red),
              ],
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text("Users",
                              style: TextStyle(fontSize: 12));
                        case 1:
                          return const Text("Sellers",
                              style: TextStyle(fontSize: 12));
                        case 2:
                          return const Text("Products",
                              style: TextStyle(fontSize: 12));
                        case 3:
                          return const Text("Orders",
                              style: TextStyle(fontSize: 12));
                        default:
                          return const Text("");
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Statistic Card
  Widget _statsCard(String title, int count, Color color) {
    return Container(
      width: 90, // Adjusted width for proper alignment
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title,
              style: TextStyle(fontSize: 14, color: color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ✅ Bar Chart Data with Labels
  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.circular(5),
          // ✅ Label on top of bars
          rodStackItems: [
            BarChartRodStackItem(
                0, y, color, BorderSide(width: 2, color: Colors.white)),
          ],
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }

  // ✅ Navigate to Pages
  Future<void> _navigateTo(BuildContext context, Widget page) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => page));
    if (mounted) await fetchStatistics();
  }
}
