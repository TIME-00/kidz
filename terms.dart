import 'package:flutter/material.dart';
import 'home.dart';

class TermsPage extends StatefulWidget {
  final bool isFromSignup; // Determine if terms should be selectable
  final VoidCallback? onAgree; // Callback when user agrees to terms

  const TermsPage({super.key, required this.isFromSignup, this.onAgree});

  @override
  _TermsPageState createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool _isAgreed = false; // Track checkbox state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        elevation: 0,
        title: const Text(
          "Terms of Service",
          style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_up, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            const Text(
              "Welcome to Our Service!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: const Text(
                  "By using this application, you agree to the following terms and conditions. "
                  "Please read carefully before proceeding.\n\n"
                  "1. You must be at least 18 years old.\n"
                  "2. Your personal data will be securely stored.\n"
                  "3. Unauthorized use of this app is prohibited.\n"
                  "4. We reserve the right to modify these terms at any time.\n"
                  "5. By continuing, you agree to comply with all terms.\n\n"
                  "Click the checkbox below to agree and continue using the app.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: widget.isFromSignup ? _isAgreed : true, // Read-only if from profile
                  activeColor: Colors.orange,
                  onChanged: widget.isFromSignup
                      ? (value) {
                          setState(() {
                            _isAgreed = value!;
                          });
                        }
                      : null, // Disable checkbox in read-only mode
                ),
                const Expanded(
                  child: Text(
                    "I agree to the Terms of Service",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isFromSignup
                      ? (_isAgreed ? Colors.orange : Colors.grey)
                      : Colors.orange, // Button always enabled in read-only mode
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: widget.isFromSignup
                    ? (_isAgreed
                        ? () {
                            if (widget.onAgree != null) {
                              widget.onAgree!();
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                                (route) => false, // Clears navigation stack
                              );
                            }
                          }
                        : null)
                      : null, 
                child: const Text(
                  "Agree and Continue",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}