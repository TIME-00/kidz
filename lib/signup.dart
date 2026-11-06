import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String selectedGender = "Male";
  bool isAgreed = false;

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate() && isAgreed) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        // ✅ Attempt to sign up
        final authResponse = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        final user = authResponse.user;
        if (user == null) {
          throw Exception("Signup failed. Please try again.");
        }

        // ✅ Add user to 'users' table
        // Upsert, not insert: the on_auth_user_created trigger already created
        // a bare profile row for this id, so a plain insert would collide.
        await _supabase.from('users').upsert({
          'id': user.id,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'gender': selectedGender,
          'mobile_number': _mobileController.text.trim(),
          'email': email,
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInUserId', user.id);

        // ✅ Show success dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Registration Successful"),
            // Email confirmation is disabled for this project, so promising a
            // verification link was untrue — the account is usable immediately.
            content: Text(
              "Your account for $email has been created.\nYou can now log in.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to login
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } on AuthException catch (e) {
        // ✅ Catch duplicate email or auth errors
        if (e.message.contains("already registered") ||
            e.message.contains("User already registered")) {
          _showSnackbar(
              "This email is already registered. Please login or use another email.",
              Colors.red);
        } else {
          _showSnackbar("Signup failed: ${e.message}", Colors.red);
        }
      } catch (e) {
        _showSnackbar("Unexpected error: $e", Colors.red);
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF16601),
      // Scrollable so the soft keyboard can shrink the viewport without
      // overflowing the form (it previously overflowed by ~103px on a phone,
      // pushing the terms checkbox and REGISTER button off screen).
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
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
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("First Name"),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        hintText: "Enter your First Name",
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "First Name required" : null,
                    ),
                    const SizedBox(height: 20),
                    const Text("Last Name"),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        hintText: "Enter your Last Name",
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Last Name required" : null,
                    ),
                    const SizedBox(height: 20),
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
                    const Text("Mobile Number"),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Enter your Mobile Number",
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Mobile Number required" : null,
                    ),
                    const SizedBox(height: 20),
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
                        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                            .hasMatch(value)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text("Password"),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "Enter your Password",
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.length < 8 ? "Password too short" : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: isAgreed,
                          onChanged: (value) =>
                              setState(() => isAgreed = value ?? false),
                        ),
                        const Expanded(
                            child: Text("I agree to the terms and conditions")),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAgreed ? Colors.orange : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate() && isAgreed) {
                            _registerUser();
                          } else {
                            _showSnackbar(
                                "Please complete all fields and agree to the terms",
                                Colors.red);
                          }
                        },
                        child: const Text("REGISTER"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                  color:
                      selectedGender == gender ? Colors.white : Colors.black),
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
