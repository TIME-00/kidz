import 'package:flutter/material.dart';
import 'package:kidz/terms.dart';
import 'account.dart';
import 'login.dart';
import 'shipping.dart';
import 'wishlist.dart';
import 'payment.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Color.fromRGBO(255, 152, 0, 1), size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10), // ✅ Spacing
            // Profile Image & Name
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    "assets/img/babyboy.jpg",
                    width: 70,  // ✅ Adjusted for better proportion
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  "Rooben Prakaash",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 30), // ✅ Spacing
            
            // Menu Items
            _buildMenuItem(
              "Account",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
              ),
            ),
            _buildMenuItem(
              "Shipping Address",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShippingAddressPage()),
              ),
            ),
            _buildMenuItem(
              "Wishlist",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              ),
            ),
            _buildMenuItem(
              "Payment Method",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentMethodsPage()),
              ),
            ),
            _buildMenuItem("Terms of Service",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsPage(isFromSignup: false)),
              ),
            ),
            _buildMenuItem("Privacy Policy"),
            
            const Spacer(), // Push Logout Button to Bottom
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(255, 152, 0, 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {},
                child: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20), // ✅ Bottom Spacing
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {IconData? icon, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Icon(icon ?? Icons.arrow_forward_ios, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}