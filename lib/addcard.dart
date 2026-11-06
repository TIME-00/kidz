import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For text input formatting
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  _AddCardPageState createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController validController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _saveCard() async {
    final String cardHolder = cardHolderController.text.trim();
    final String cardNumber = cardNumberController.text.trim();
    final String validDate = validController.text.trim();
    final String cvv = cvvController.text.trim();

    // Get current user ID
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in!")),
      );
      return;
    }
    final String userId = user.id;

    // Validation
    if (cardHolder.isEmpty ||
        cardNumber.isEmpty ||
        validDate.isEmpty ||
        cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // Check if validDate matches MM/YY format
    final RegExp validDateRegex = RegExp(r'^(0[1-9]|1[0-2])/\d{2}$');
    if (!validDateRegex.hasMatch(validDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Invalid expiration date. Use MM/YY format.")),
      );
      return;
    }

    try {
      await supabase.from('bankingcard').insert({
        'user_id': userId, // Include user_id to match foreign key
        'cardholdername': cardHolder,
        'cardnumber': cardNumber,
        'valid': validDate,
        'cvv': cvv,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Card added successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add Card",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(
              "Card Holder", "Enter Name", cardHolderController, false),
          _buildTextField(
              "Card Number", "Enter Card Number", cardNumberController, true),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns fields at top
            children: [
              Expanded(
                  flex: 1, // Ensures equal width
                  child: _buildTextField(
                      "Valid (MM/YY)", "MM/YY", validController, true,
                      formatAsExpiryDate: true)),
              const SizedBox(width: 10),
              Expanded(
                  flex: 1, // Ensures equal width
                  child: _buildTextField(
                      "CVV", "Enter CVV", cvvController, true,
                      maxLength: 3)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: _saveCard,
            child: const Text("Save Changes",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller, bool isNumeric,
      {bool formatAsExpiryDate = false, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          inputFormatters: [
            if (isNumeric) FilteringTextInputFormatter.digitsOnly,
            if (formatAsExpiryDate) LengthLimitingTextInputFormatter(5),
            if (formatAsExpiryDate)
              TextInputFormatter.withFunction((oldValue, newValue) {
                String text = newValue.text
                    .replaceAll('/', ''); // Remove existing slashes
                if (text.length > 4) return oldValue;
                if (text.length >= 3) {
                  return TextEditingValue(
                    text: '${text.substring(0, 2)}/${text.substring(2)}',
                    selection: TextSelection.collapsed(offset: text.length + 1),
                  );
                }
                return newValue;
              }),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.orange.shade200,
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLength: maxLength,
        ),
      ],
    );
  }
}
