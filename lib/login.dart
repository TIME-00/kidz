import 'package:flutter/material.dart';
import 'package:kidz_store/signup.dart';
import 'package:kidz_store/home.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'guest_home.dart';
import 'admin_dashboard.dart';
import 'admin_access.dart';
import 'session_routing.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key, this.access});
  final AdminAccess? access;

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  late final _access = widget.access ?? AdminAccess(Supabase.instance.client);
  bool _submitting = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _loginUser() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final String email = _emailOrPhoneController.text.trim();
    final String password = _passwordController.text;
    setState(() => _submitting = true);

    try {
      await _access.signIn(
        email: email,
        password: password,
      );

      final user = await _access.verifyCurrentUser();
      if (!mounted) return;

      if (user != null) {
        if (user.emailConfirmedAt != null) {
          final destination =
              startupDestinationFor(_access.session, verifiedUser: user);
          if (destination == StartupDestination.login) {
            _showSnackbar(
                'Your session has expired. Please sign in again.', Colors.red);
            return;
          }
          _showSnackbar("Login successful!", Colors.green);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => destination == StartupDestination.admin
                    ? AdminDashboard(access: _access)
                    : const HomePage()),
          );
        } else {
          _showSnackbar(
            "Please verify your email before logging in.",
            Colors.red,
          );
        }
      } else {
        _showSnackbar("Invalid login credentials.", Colors.red);
      }
    } catch (_) {
      if (mounted) {
        _showSnackbar(
            'Unable to sign in. Check your credentials and try again.',
            Colors.red);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF16601),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 50),
              Lottie.asset(
                "assets/anime/tracking-order-online.json",
                width: 150,
                height: 150,
                repeat: true,
              ),
              const SizedBox(height: 30),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 123, 0),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _submitting ? null : _loginUser,
                          child: const Text("CONTINUE"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "New to Kidz? Sign Up",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(child: Text("OR")),
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const GuestHomePage()),
                            );
                          },
                          child: const Text("Continue as Guest"),
                        ),
                      ),
                      const SizedBox(height: 10),
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
