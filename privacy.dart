import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        elevation: 0,
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Our Commitment to Privacy",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: const Text(
                  "We value your privacy and are committed to protecting your personal data. "
                  "This Privacy Policy explains how we collect, use, and share your information.\n\n"
                  
                  "1. **Information We Collect**\n"
                  "   - Personal details (name, email, phone number)\n"
                  "   - Payment and transaction history\n"
                  "   - Device and usage data\n\n"
                  
                  "2. **How We Use Your Information**\n"
                  "   - To provide and improve our services\n"
                  "   - To process transactions securely\n"
                  "   - To communicate with you (updates, promotions, support)\n\n"
                  
                  "3. **Sharing Your Data**\n"
                  "   - We do not sell your personal data.\n"
                  "   - We may share your data with trusted partners for payment processing and order fulfillment.\n\n"
                  
                  "4. **Your Rights & Choices**\n"
                  "   - You can update your information in your account settings.\n"
                  "   - You can request data deletion by contacting support.\n\n"
                  
                  "5. **Security Measures**\n"
                  "   - We implement security measures to protect your data.\n"
                  "   - Always keep your password confidential.\n\n"
                  
                  "By using this app, you agree to our Privacy Policy. "
                  "For more details, contact support at **support@kidzapp.com**.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}