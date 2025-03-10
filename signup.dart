import 'package:flutter/material.dart';
import 'package:kidz/terms.dart'; // Import TermsPage

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String selectedGender = "Male"; // Default gender selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF16601), // Orange Background
      body: Center(
        child: Container(
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
              const TextField(
                decoration: InputDecoration(
                  hintText: "Enter your First Name",
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Last Name
              const Text("Last Name"),
              const TextField(
                decoration: InputDecoration(
                  hintText: "Enter your Last Name",
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Gender Selection (Updated UI)
              const Text("Gender"),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGender = "Male";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedGender == "Male"
                              ? Colors.orange
                              : Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.male,
                                color: selectedGender == "Male"
                                    ? Colors.white
                                    : Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              "Male",
                              style: TextStyle(
                                color: selectedGender == "Male"
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGender = "Female";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedGender == "Female"
                              ? Colors.orange
                              : Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.female,
                                color: selectedGender == "Female"
                                    ? Colors.white
                                    : Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              "Female",
                              style: TextStyle(
                                color: selectedGender == "Female"
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mobile Number
              const Text("Mobile Number"),
              const TextField(
                decoration: InputDecoration(
                  hintText: "Enter your Mobile Number",
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "OTP will be sent on this Mobile No. for verification.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Email ID
              const Text("Email ID"),
              const TextField(
                decoration: InputDecoration(
                  hintText: "Enter your Email ID",
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Password
              const Text("Password"),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Enter your Password",
                  border: const UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility_off),
                    onPressed: () {},
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Password must be at least 8 characters long with 1 Uppercase, 1 Lowercase & 1 Numeric character.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Register Button -> Navigates to Home Page
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 123, 0),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsPage(isFromSignup: true)),
                    );
                  },
                  child: const Text("REGISTER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}