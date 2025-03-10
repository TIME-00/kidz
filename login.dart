import 'package:flutter/material.dart';
import 'package:kidz/seller.dart';
import 'package:kidz/signup.dart';
import 'package:kidz/home.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  _LoginRegisterScreenState createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers for Input Fields
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ✅ Function to Authenticate User
  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // ✅ Authenticate with Supabase Auth
        final authResponse = await _supabase.auth.signInWithPassword(
          email: _emailOrPhoneController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (authResponse.user != null) {
          print("✅ Login Successful! User ID: ${authResponse.user!.id}");

          // ✅ Fetch user details from the `users` table
          final userData = await _supabase
              .from('users')
              .select()
              .eq('id', authResponse.user!.id)
              .maybeSingle();

          if (userData == null) {
            _showSnackbar("User data not found.", Colors.red);
            return;
          }

          _showSnackbar("Login successful!", Colors.green);

          // ✅ Navigate to Home Page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          _showSnackbar("Login failed. Please try again.", Colors.red);
        }
      } catch (e) {
        _showSnackbar("Error: ${e.toString()}", Colors.red);
      }
    }
  }

  // ✅ Function to Show Snackbar Messages with Color
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color, // ✅ Custom color for success/error
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF16601),
      resizeToAvoidBottomInset: true, // ✅ Prevents overflow issues
      body: SingleChildScrollView(
        // ✅ Makes content scrollable when keyboard opens
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Animation
              Lottie.asset(
                "assets/anime/tracking-order-online.json",
                width: 150,
                height: 150,
                repeat: true,
              ),
              const SizedBox(height: 30),

              // ✅ Login Form
              Container(
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
                      const Text(
                        "Login / Register",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Email / Phone Input
                      const Text("Email ID / Mobile No."),
                      TextFormField(
                        controller: _emailOrPhoneController,
                        decoration: const InputDecoration(
                          hintText: "Enter your Email or Mobile No.",
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "This field is required" : null,
                      ),
                      const SizedBox(height: 20),

                      // ✅ Password Input
                      const Text("Password"),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: "Enter your Password",
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Password required" : null,
                      ),
                      const SizedBox(height: 20),

                      // ✅ Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 123, 0),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _loginUser, // ✅ Call Login Function
                          child: const Text("CONTINUE"),
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Center(child: Text("OR")),
                      const SizedBox(height: 10),

                      // ✅ Sign Up Navigation
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignupScreen()),
                            );
                          },
                          child: const Text(
                            "New to Kidz? Sign Up",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ✅ Terms and Conditions
                      const Text(
                        "By continuing, you agree to Kidz Conditions of Use and Privacy Notice.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
