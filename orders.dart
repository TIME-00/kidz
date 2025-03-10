import 'package:flutter/material.dart';
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
  String selectedFilter = "All";
  String searchQuery = "";

  List<Map<String, dynamic>> orders = [
    {
      "image": "assets/img/p1.jpg",
      "name": "Babyoye kids shoes",
      "status": "Delivered on 4 Feb, 2025",
      "statusColor": Colors.green,
      "payment": "COD",
      "button": "Track",
      "buttonColor": const Color.fromARGB(255, 255, 123, 0),
      "date": DateTime(2025, 2, 4),
    },
    {
      "image": "assets/img/p2.jpg",
      "name": "Babyoye kids shoes",
      "status": "Returned on 28 Jul, 2022",
      "statusColor": const Color.fromARGB(255, 243, 191, 3),
      "payment": "DuitNow",
      "button": "Re-order",
      "buttonColor": const Color.fromARGB(255, 255, 123, 00),
      "date": DateTime(2022, 7, 28),
    },
    {
      "image": "assets/img/p3.jpg",
      "name": "Babyoye kids T-shirts",
      "status": "Refunded on 10 Aug, 2022",
      "statusColor": Colors.red,
      "payment": "DuitNow",
      "button": "Re-order",
      "buttonColor": const Color.fromARGB(255, 255, 123, 0),
      "date": DateTime(2022, 8, 10),
    },
  ];

  // ✅ Function to filter orders based on selected category
  List<Map<String, dynamic>> getFilteredOrders() {
    DateTime now = DateTime.now();
    DateTime tenDaysAgo = now.subtract(const Duration(days: 10));

    return orders.where((order) {
      if (selectedFilter == "All") return true;
      if (selectedFilter == "Cancelled" && order["status"].contains("Cancelled")) return true;
      if (selectedFilter == "Returns" && order["status"].contains("Returned")) return true;
      if (selectedFilter == "Refunds" && order["status"].contains("Refunded")) return true;
      if (selectedFilter == "Last 10 Days" && order["date"].isAfter(tenDaysAgo)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredOrders = getFilteredOrders().where((order) {
      return order["name"].toLowerCase().contains(searchQuery.toLowerCase());
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
            const Text(
              "Rooben",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
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
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    width: 100,
                                    height: 100,
                                    child: Image.asset(order["image"], fit: BoxFit.cover),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(order["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text(order["status"], style: TextStyle(color: order["statusColor"])),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                                                child: Text(order["payment"], style: const TextStyle(color: Colors.black)),
                                              ),
                                              const SizedBox(width: 5),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: order["buttonColor"],
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () {},
                                                child: Text(order["button"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
                                backgroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CartPage()),
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