import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCardPage extends StatefulWidget {
  final int cardId; // Unique ID of the card in the database

  const EditCardPage({super.key, required this.cardId});

  @override
  _EditCardPageState createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController validController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCardDetails();
  }

  /// **Load Card Details from Supabase**
  Future<void> _loadCardDetails() async {
    try {
      final response = await supabase
          .from('bankingcard')
          .select()
          .eq('id', widget.cardId)
          .maybeSingle(); // ✅ Prevents crash if no data is found

      if (response == null) {
        // ✅ Show a message and close the modal if no card is found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Card not found!")),
        );
        Navigator.pop(context);
        return;
      }

      // ✅ Update text fields with retrieved data
      setState(() {
        cardHolderController.text = response['cardholdername'] ?? "";
        cardNumberController.text = response['cardnumber'] ?? "";
        validController.text = response['valid'] ?? "";
        cvvController.text = response['cvv'] ?? "";
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading card: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  /// **Update Card in Supabase**
  Future<void> _updateCard() async {
    final String cardHolder = cardHolderController.text.trim();
    final String cardNumber = cardNumberController.text.trim();
    final String validDate = validController.text.trim();
    final String cvv = cvvController.text.trim();

    if (cardHolder.isEmpty ||
        cardNumber.isEmpty ||
        validDate.isEmpty ||
        cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      await supabase.from('bankingcard').update({
        'cardholdername': cardHolder,
        'cardnumber': cardNumber,
        'valid': validDate,
        'cvv': cvv,
      }).eq('id', widget.cardId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Card updated successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating card: $e")),
      );
    }
  }

  /// **Delete Card from Supabase**
  Future<void> _deleteCard() async {
    try {
      await supabase.from('bankingcard').delete().eq('id', widget.cardId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Card deleted successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting card: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 30),
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Edit Card",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.white, size: 24),
                        onPressed: _deleteCard,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField("Card Holder", cardHolderController),
                _buildTextField("Card Number", cardNumberController),
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildTextField("Valid (MM/YY)", validController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField("CVV", cvvController)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _updateCard,
                  child: const Text("Save Changes",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
    );
  }

  /// **Reusable Text Field Widget**
  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.orange.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
