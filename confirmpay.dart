import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // ✅ For animation
import 'home.dart'; // ✅ Import home page
import 'orders.dart'; // ✅ Import orders page

class ConfirmPaymentPage extends StatelessWidget {
  const ConfirmPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA), // Light background
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Animation
          Center(
            child: Lottie.asset(
              "assets/anime/woman-shopping-online.json", // ✅ Replace with your Lottie animation
              width: 120,
              height: 120,
              repeat: false,
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Congratulations Text
          const Text(
            "Congratulations",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your Order has been Successfully placed",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // ✅ Continue Shopping Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false, // Clears the stack
                );
              },
              child: const Text("Continue Shopping", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ View All Orders Button
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const OrdersPage()), // ✅ Navigate to Orders Page
              );
            },
            child: const Text("View all Orders", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}