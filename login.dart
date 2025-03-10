import 'package:flutter/material.dart';
import 'package:kidz/signup.dart';
import 'package:kidz/home.dart'; // Import HomePage
import 'package:lottie/lottie.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginRegisterScreen(),
    );
  }
}

class LoginRegisterScreen extends StatelessWidget {
  const LoginRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF16601), // Orange Background
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Centers content vertically
          children: [
            // ✅ Animation (Above Login Box)
            Lottie.asset(
              "assets/anime/tracking-order-online.json", // ✅ Replace with your Lottie animation
              width: 150,
              height: 150,
              repeat: true,
            ),

            const SizedBox(height: 30), // ✅ Space between animation and box

            // ✅ Login Box
            Container(
              width: 350,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Login / Register",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Email/Mobile Field
                  const Text("Email ID/Mobile No."),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: "Enter your Email or Mobile No.",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Continue Button -> Navigate to Home
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      },
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
          ],
        ),
      ),
    );
  }
}