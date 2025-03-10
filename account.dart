import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final supabase = Supabase.instance.client;
  
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  final TextEditingController emailController = TextEditingController();
  String selectedGender = "Male"; // Default gender selection
  
  String userId = "";
  bool isLoading = true;
  bool hasChanges = false; 

   /// ✅ Stores Original Values to Track Changes
  String originalFirstName = "";
  String originalLastName = "";
  String originalPhone = "";
  String originalGender = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();

  /// ✅ Listen for text field changes
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    firstNameController = TextEditingController(text: userProvider.userData?["first_name"] ?? "");
    lastNameController = TextEditingController(text: userProvider.userData?["last_name"] ?? "");
    phoneController = TextEditingController(text: userProvider.userData?["mobile_number"] ?? "");
    selectedGender = userProvider.userData?["gender"] ?? "Male";

    firstNameController.addListener(checkForChanges);
    lastNameController.addListener(checkForChanges);
    phoneController.addListener(checkForChanges);
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
          originalFirstName = response['first_name'] ?? "";
          originalLastName = response['last_name'] ?? "";
          originalPhone = response['mobile_number'] ?? "";
          originalGender = response['gender'] ?? "Male"; // Default to Male

          firstNameController.text = response['first_name'] ?? "";
          lastNameController.text = response['last_name'] ?? "";
          emailController.text = response['email'] ?? "";
          phoneController.text = response['mobile_number'] ?? "";
          selectedGender = response['gender'] ?? "Male"; // Default to Male if null
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }

  /// ✅ Check if any field has changed
  void checkForChanges() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      hasChanges = firstNameController.text != userProvider.userData?["first_name"] ||
          lastNameController.text != userProvider.userData?["last_name"] ||
          phoneController.text != userProvider.userData?["mobile_number"] ||
          selectedGender != userProvider.userData?["gender"];
    });
  }

  /// ✅ Update user data in Supabase
  Future<void> updateUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateUserData({
      "first_name": firstNameController.text.trim(),
      "last_name": lastNameController.text.trim(),
      "mobile_number": phoneController.text.trim(),
      "gender": selectedGender,
    });

    setState(() {
      hasChanges = false; // Reset changes tracking
    });
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

  /// ✅ Delete user account (with confirmation dialog)
  Future<void> deleteAccount() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!confirmDelete) return;

    try {
      // ✅ Delete user data from the 'users' table
      await supabase.from('users').delete().eq('id', userId);

      // ✅ Sign the user out and delete their account from auth
      await supabase.auth.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully!")),
      );

      // ✅ Navigate to login or home page
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print("❌ Error deleting account: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.userData == null) return const CircularProgressIndicator();
    
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
                  _buildDropdown(),
                  const SizedBox(height: 30),


                  /// ✅ Save Changes Button (Disabled if no changes)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasChanges ? Colors.orange : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: hasChanges ? updateUser : null,
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
                  const SizedBox(height: 15),

                  /// ❌ Delete Account Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: deleteAccount,
                      child: const Text("Delete Account", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// ✅ Helper Function to Build TextFields
  Widget _buildTextField(TextEditingController controller, {bool isEnabled = true}) {
    return TextField(
      controller: controller,
      enabled: isEnabled,
      onChanged: (value) => checkForChanges(),
      decoration: InputDecoration(
        filled: true,
        fillColor: isEnabled ? Colors.orange : Colors.grey[300],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16),
    );
  }

  /// ✅ Helper Function for Gender Dropdown
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGender,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: Colors.orange,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedGender = newValue;
                checkForChanges(); // ✅ Detect gender change
              });
            }
          },
          items: <String>['Male', 'Female']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// ✅ Helper Function for Buttons
  Widget _buildButton(String text, Color color, VoidCallback onPressed, {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : color,
          side: isOutlined ? BorderSide(color: color, width: 2) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: isOutlined ? color : Colors.white, fontSize: 16)),
      ),
    );
  }
}