import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_invoice.dart';
import 'cart.dart';
import 'home.dart';
import 'profile.dart';
import 'notification.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orders = [];
  String selectedFilter = "All";
  String searchQuery = "";
  String userFirstName = "User";

  @override
  void initState() {
    super.initState();
    fetchOrders();
    fetchUserName();
  }

  Future<void> fetchOrders() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('orders')
        .select('*')
        .eq('user_id', user.id)
        .order('order_date', ascending: false);

    setState(() {
      orders = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> fetchUserName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('users')
        .select('first_name')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      setState(() {
        userFirstName = response['first_name'] ?? "User";
      });
    }
  }

  List<Map<String, dynamic>> getFilteredOrders() {
    DateTime now = DateTime.now();
    DateTime tenDaysAgo = now.subtract(const Duration(days: 10));

    return orders.where((order) {
      if (selectedFilter == "All") return true;
      if (selectedFilter == "Cancelled" && order["status"].contains("Cancelled")) return true;
      if (selectedFilter == "Returns" && order["status"].contains("Returned")) return true;
      if (selectedFilter == "Refunds" && order["status"].contains("Refunded")) return true;
      if (selectedFilter == "Last 10 Days" && DateTime.parse(order["order_date"]).isAfter(tenDaysAgo)) return true;
      return false;
    }).toList();
  }

  String getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredOrders = getFilteredOrders().where((order) {
      return order["order_items"][0]["product_name"]
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()), // ✅ Navigate to Profile Page
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  "assets/img/babyboy.jpg",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            // Column to show Greeting and Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(getGreeting(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 2),
                Text(
                  userFirstName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black, size: 35),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationPage()),
                  );
                },
              ),
              Positioned(
                right: 5, // ✅ Move closer to the top-right corner
                top: 5,   // ✅ Slightly adjust upwards
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationPage()), // ✅ Navigate to Notification Page
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(209, 255, 0, 0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2), // ✅ Adds a subtle shadow
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20), // ✅ Ensures a circular shape
                    child: const Center(
                      child: Text(
                        "10", // ✅ Notification Count
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // ✅ Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 179, 0),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.black45),
                      hintText: "Search here...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // ✅ Filter Categories
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      categoryChip("All"),
                      categoryChip("Cancelled"),
                      categoryChip("Returns"),
                      categoryChip("Refunds"),
                      categoryChip("Last 10 Days"),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // ✅ Orders List
                Expanded(
                  child: filteredOrders.isEmpty
                      ? const Center(child: Text("No orders found"))
                      : ListView.builder(
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => OrderInvoicePage(order: order)),
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      order["order_items"][0]["product_image"],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text("Order ID: ${order["id"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("Total: RM ${order["total_price"].toStringAsFixed(2)}"),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(order["status"], style: const TextStyle(color: Colors.green)),
                                      Text(order["order_date"].split("T")[0]),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                       ),
                      ],
                    ),
                  ),
                  // Floating Bottom Navigation Bar
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        height: 70,
                        width: 250,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [BoxShadow(color: const Color.fromARGB(255, 158, 158, 158), blurRadius: 10, spreadRadius: 2)],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HomePage()),
                                    );
                                  },
                                  child: bottomNavItem(Icons.shopping_bag, "Home", isActive: false),
                                ),
                                const SizedBox(width: 50),
                                bottomNavItem(Icons.shopping_bag, "Orders", isActive: true),
                              ],
                            ),
                            Positioned(
                              top: 7,
                              child: FloatingActionButton(
                                backgroundColor: const Color.fromARGB(255, 179, 0, 211),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CartPage(cartItems: [])), // ✅ Ensure `cartItems` is passed
                                  );
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.shopping_cart, size: 28, color: Colors.white),
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Color.fromARGB(255, 255, 123, 0), shape: BoxShape.circle),
                                        child: const Text("03", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

  Widget categoryChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = text;
          });
        },
        child: Chip(
          backgroundColor: selectedFilter == text ? const Color.fromARGB(255, 255, 123, 0) : Colors.white,
          label: Text(text, style: TextStyle(color: selectedFilter == text ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selectedFilter == text ? Colors.orange : Colors.grey)),
        ),
      ),
    );
  }

  Widget bottomNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? const Color.fromARGB(255, 255, 123, 0) : const Color.fromARGB(255, 158, 158, 158), size: 28),
        Text(label, style: TextStyle(color: isActive ? const Color.fromARGB(255, 255, 123, 0) : const Color.fromARGB(255, 158, 158, 158), fontWeight: FontWeight.bold)),
      ],
    );
  }
}