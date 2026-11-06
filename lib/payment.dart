import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'addcard.dart';
import 'editcard.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  _PaymentMethodsPageState createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cards = [];
  Map<String, dynamic>? selectedCard;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      // Handle the case when no user is authenticated
      setState(() {
        isLoading = false;
        cards = [];
      });
      return;
    }

    final response = await supabase.from('bankingcard').select().eq(
        'user_id', userId); // Ensure 'user_id' matches the current user's ID

    setState(() {
      if (response.isNotEmpty) {
        cards = List<Map<String, dynamic>>.from(response);
        selectedCard = cards.first; // Default to first card
      } else {
        cards = [];
        selectedCard = null;
      }
      isLoading = false;
    });
  }

  String formatValidDate(String valid) {
    return valid.replaceAll('-', '/'); // Change "-" to "/"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        elevation: 0,
        title: const Text(
          "Payment",
          style: TextStyle(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up,
              color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),

            // Card Selection
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (cards.isNotEmpty)
              Column(
                children: [
                  DropdownButton<Map<String, dynamic>>(
                    value: selectedCard,
                    isExpanded: true,
                    items: cards.map((card) {
                      return DropdownMenuItem(
                        value: card,
                        child: Text(
                            "•••• ${card['cardnumber'].substring(card['cardnumber'].length - 4)}"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCard = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildCardDisplay(),
                ],
              )
            else
              const Center(child: Text("No cards found. Add a new card.")),

            const SizedBox(height: 20),

            // Add New Card Button
            Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton(
                backgroundColor: const Color.fromARGB(255, 255, 152, 0),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddCardPage(),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDisplay() {
    if (selectedCard == null) return const SizedBox.shrink();

    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              "assets/img/debitcard.jpg",
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.settings,
                  color: Color.fromARGB(255, 255, 152, 0)),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => EditCardPage(cardId: selectedCard!['id']),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  "••••  ••••  ••••  ${selectedCard!['cardnumber'].substring(selectedCard!['cardnumber'].length - 4)}",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedCard!['cardholdername'].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 5),
                Text(
                  formatValidDate(selectedCard!['valid']),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
