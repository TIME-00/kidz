import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Store user ID locally
import 'terms.dart';
import 'home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Controllers for user input
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedGender = "Male"; // Default gender
  bool isAgreed = false; // Track Terms Agreement

  // ✅ Function to Register User in Supabase Auth & Users Table
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate() && isAgreed) {
      try {
        // ✅ Step 1: Register in Supabase Authentication
        final String email = _emailController.text.trim(); // ✅ Trim spaces

        final authResponse = await _supabase.auth.signUp(
          email: email, // ✅ Pass trimmed email
          password: _passwordController.text.trim(),
        );

        final userId = authResponse.user?.id;
        if (userId == null) {
          throw Exception("Failed to register user in authentication.");
        }

        // ✅ Step 2: Store Additional Details in `users` Table
        await _supabase.from('users').insert({
          'id': userId, // ✅ Use Supabase Auth user ID
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'gender': selectedGender,
          'mobile_number': _mobileController.text.trim(),
          'email': _emailController.text.trim(),
        });

        // ✅ Step 3: Store `user_id` Locally for Future Use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInUserId', userId);

        print("✅ Registration Successful! User ID: $userId");

        // ✅ Navigate to Home Page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false, // Clears previous routes
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  // ✅ Navigate to Terms Page Before Registering
  void _navigateToTerms() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TermsPage(
            isFromSignup: true,
            onAgree: () {
              setState(() {
                isAgreed = true;
              });
              _registerUser(); // ✅ Register after agreeing to terms
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF16601),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Register",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // First Name
                const Text("First Name"),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    hintText: "Enter your First Name",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "First Name required" : null,
                ),
                const SizedBox(height: 20),

                // Last Name
                const Text("Last Name"),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    hintText: "Enter your Last Name",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Last Name required" : null,
                ),
                const SizedBox(height: 20),

                // Gender Selection
                const Text("Gender"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _genderOption("Male"),
                    const SizedBox(width: 10),
                    _genderOption("Female"),
                  ],
                ),
                const SizedBox(height: 20),

                // Mobile Number
                const Text("Mobile Number"),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "Enter your Mobile Number",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Mobile Number required" : null,
                ),
                const SizedBox(height: 20),

                // Email ID
                const Text("Email ID"),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: "Enter your Email ID",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                      return "Enter a valid email address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                const Text("Password"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Enter your Password",
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) => value!.length < 8 ? "Password too short" : null,
                ),
                const SizedBox(height: 20),

                // Register Button -> Navigate to Terms Page
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    onPressed: _navigateToTerms, // ✅ Navigate to Terms before Registering
                    child: const Text("REGISTER"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Gender Selection Widget
  Widget _genderOption(String gender) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selectedGender == gender ? Colors.orange : Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(gender == "Male" ? Icons.male : Icons.female,
                  color: selectedGender == gender ? Colors.white : Colors.black),
              const SizedBox(width: 8),
              Text(
                gender,
                style: TextStyle(
                  color: selectedGender == gender ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}