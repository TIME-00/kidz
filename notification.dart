import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int selectedTab = 0; // 0: Activity, 1: Promotions, 2: Messages

  final List<Map<String, dynamic>> activityNotifications = [
    {"image": "assets/img/p1.jpg", "message": "Your Order number 9885445ba76 has been shipped", "time": "30 m ago"},
    {"image": "assets/img/p2.jpg", "message": "Your Order number 9885445ba76 has been shipped", "time": "30 m ago"},
    {"image": "assets/img/p3.jpg", "message": "Your Order number 9885445ba76 has been shipped", "time": "30 m ago"},
  ];

  final List<Map<String, dynamic>> promotions = [
    {"title": "20% OFF on Kids Wear!", "desc": "Use Code: KIDS20", "image": "assets/img/p4.jpg"},
    {"title": "Buy 1 Get 1 Free", "desc": "Valid for selected items", "image": "assets/img/p5.jpg"},
  ];

  final List<Map<String, dynamic>> messages = [
    {"name": "Seller A", "message": "Your item is ready for shipment!", "time": "1h ago"},
    {"name": "Seller B", "message": "We have new arrivals for you!", "time": "2h ago"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Notification",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15), // ✅ Added Space Between Header and Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton("Activity", 0),
              _buildTabButton("Promotions", 1),
              _buildTabButton("Messages", 2),
            ],
          ),
          const SizedBox(height: 15), // ✅ Added More Space Below Tabs
          Expanded(
            child: selectedTab == 0
                ? _buildActivityTab()
                : selectedTab == 1
                    ? _buildPromotionsTab()
                    : _buildMessagesTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView.builder(
      itemCount: activityNotifications.length,
      itemBuilder: (context, index) {
        final item = activityNotifications[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15), // ✅ Increased Space Between Cards
          child: ListTile(
            leading: Image.asset(item["image"], width: 50, height: 50, fit: BoxFit.cover),
            title: Text(item["message"], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Track your Order", style: TextStyle(color: Colors.blue)),
            trailing: Text(item["time"]),
          ),
        );
      },
    );
  }

  Widget _buildPromotionsTab() {
    return ListView.builder(
      itemCount: promotions.length,
      itemBuilder: (context, index) {
        final promo = promotions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15), // ✅ Added Spacing
          child: ListTile(
            leading: Image.asset(promo["image"], width: 50, height: 50, fit: BoxFit.cover),
            title: Text(promo["title"], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(promo["desc"]),
          ),
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15), // ✅ Added Spacing
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
            title: Text(msg["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(msg["message"]),
            trailing: Text(msg["time"]),
          ),
        );
      },
    );
  }
}