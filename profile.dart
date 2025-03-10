import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'seller.dart';
import 'add_product.dart';
import 'account.dart';
import 'login.dart';
import 'shipping.dart';
import 'wishlist.dart';
import 'payment.dart';
import 'terms.dart';
import 'privacy.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  String fullName = "Loading..."; // Placeholder until data is fetched
  bool isSeller = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  /// ✅ Fetch user profile details from `users` table
  Future<void> fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final userData = await supabase
          .from('users')
          .select('first_name, last_name')
          .eq('id', user.id)
          .maybeSingle();

      final sellerData = await supabase
          .from('sellers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        fullName = userData != null
            ? "${userData['first_name']} ${userData['last_name']}"
            : "User";
        isSeller = sellerData != null;
        isLoading = false;
      });
    } catch (e) {
      print("⚠️ Error fetching user data: $e");
      setState(() => isLoading = false);
    }
  }

  /// ✅ Handle "Become a Seller" Button Click
  Future<void> handleSellerNavigation() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final sellerData = await supabase
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (sellerData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellerAddProductPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellerRegisterPage()),
      ).then((_) => fetchUserProfile()); // Refresh seller status after return
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.orange, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ✅ Profile Image & Name
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    "assets/img/babyboy.jpg",
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // ✅ Menu Items
            _buildMenuItem(
              "Account",
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
              ),
            ),
            _buildMenuItem(
              "Shipping Address",
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ShippingAddressPage()),
              ),
            ),
            _buildMenuItem(
              "Wishlist",
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const WishlistPage()),
              ),
            ),
            _buildMenuItem(
              "Payment Method",
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
              ),
            ),

            // ✅ "Become a Seller" changes dynamically to "Add Product"
            _buildMenuItem(
              isSeller ? "Seller Dashboard" : "Become a Seller",
              onTap: handleSellerNavigation,
            ),

            _buildMenuItem(
              "Terms of Service",
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TermsPage(isFromSignup: false)),
              ),
            ),
            _buildMenuItem(
              "Privacy Policy",
              onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              ),
            ),

            const Spacer(),

            // ✅ Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  await supabase.auth.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
                    (route) => false,
                  );
                },
                child: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// ✅ Menu Item Widget
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