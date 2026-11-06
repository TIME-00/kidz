import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // ✅ Only Promotions Notifications (Removed Activity & Messages)
  final List<Map<String, dynamic>> promotions = [
    {
      "title": "20% OFF on Kids Wear!",
      "desc": "Use Code: KIDS20",
      "image": "assets/img/p4.jpg"
    },
    {
      "title": "Buy 1 Get 1 Free",
      "desc": "Valid for selected items",
      "image": "assets/img/p5.jpg"
    },
    {
      "title": "Flash Sale! Up to 50% OFF",
      "desc": "Limited time only!",
      "image": "assets/img/p6.jpg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7B00),
        elevation: 0,
        title: const Text(
          "Notification",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up,
              color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          // ✅ Single Tab for Promotions (Removed Activity & Messages)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton("Promotions"),
            ],
          ),
          const SizedBox(height: 15),
          // ✅ Only Display Promotions
          Expanded(child: _buildPromotionsTab()),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.blue.shade100, // ✅ Fixed color for Promotions
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPromotionsTab() {
    return ListView.builder(
      itemCount: promotions.length,
      itemBuilder: (context, index) {
        final promo = promotions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
          child: ListTile(
            leading: Image.asset(promo["image"],
                width: 50, height: 50, fit: BoxFit.cover),
            title: Text(promo["title"],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(promo["desc"]),
          ),
        );
      },
    );
  }
}
