import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final supabase = Supabase.instance.client;
  
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  
  String userId = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  /// ✅ Fetch user data from Supabase
  Future<void> fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("⚠️ User not logged in");
      return;
    }

    try {
      final response = await supabase
          .from('users')
          .select('first_name, last_name, email, mobile_number, gender')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          userId = user.id;
          firstNameController.text = response['first_name'] ?? "";
          lastNameController.text = response['last_name'] ?? "";
          emailController.text = response['email'] ?? "";
          phoneController.text = response['mobile_number'] ?? "";
          genderController.text = response['gender'] ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }

  /// ✅ Update user data in Supabase
  Future<void> updateUserData() async {
    try {
      await supabase.from('users').update({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'mobile_number': phoneController.text.trim(),
        'gender': genderController.text.trim(),
      }).eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      print("❌ Error updating user data: $e");
    }
  }

  /// ✅ Send password reset email
  Future<void> resetPassword() async {
    try {
      await supabase.auth.resetPasswordForEmail(emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent! Check your email.")),
      );
    } catch (e) {
      print("❌ Error sending password reset email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text(
          "Account",
          style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const Text(
                    "Your Personal Information",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 20),

                  /// ✅ Profile Picture & Name
                  Row(
                    children: [
                      Stack(
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
                        ],
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "${firstNameController.text} ${lastNameController.text}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// ✅ Editable Fields
                  const Text("First Name"),
                  _buildTextField(firstNameController),
                  const SizedBox(height: 10),

                  const Text("Last Name"),
                  _buildTextField(lastNameController),
                  const SizedBox(height: 10),

                  const Text("Email"),
                  _buildTextField(emailController, isEnabled: false),
                  const SizedBox(height: 10),

                  const Text("Phone Number"),
                  _buildTextField(phoneController),
                  const SizedBox(height: 10),

                  const Text("Gender"),
                  _buildTextField(genderController),
                  const SizedBox(height: 30),

                  /// ✅ Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: updateUserData,
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// ✅ Reset Password Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: resetPassword,
                      child: const Text("Reset Password", style: TextStyle(color: Colors.orange, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// ✅ Helper Function to Build TextFields
  Widget _buildTextField(TextEditingController controller, {bool isPassword = false, bool isEnabled = true}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      enabled: isEnabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: isEnabled ? Colors.orange : Colors.grey[300],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16),
    );
  }
}