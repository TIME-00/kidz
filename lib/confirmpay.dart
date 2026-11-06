import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home.dart';
import 'orders.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmPaymentPage extends StatelessWidget {
  final List<dynamic> purchasedCartIds;
  const ConfirmPaymentPage({super.key, required this.purchasedCartIds});

  Future<void> clearPurchasedItems() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null && purchasedCartIds.isNotEmpty) {
      await supabase
          .from('cart')
          .delete()
          .inFilter('id', purchasedCartIds.whereType<int>().toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    clearPurchasedItems(); // Clear cart as soon as confirmation page loads

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Lottie.asset(
              "assets/anime/woman-shopping-online.json",
              width: 120,
              height: 120,
              repeat: false,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Congratulations",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your Order has been Successfully placed",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              },
              child: const Text("Continue Shopping",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const OrdersPage()),
                (route) => false,
              );
            },
            child: const Text("View all Orders",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
