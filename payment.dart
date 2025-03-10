import 'package:flutter/material.dart';
import 'addcard.dart';
import 'editcard.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  _PaymentMethodsPageState createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<Map<String, dynamic>> transactions = [
    {
      "date": "April, 19 2020 12:31",
      "order": "#92287157",
      "amount": "-RM 14.00",
      "icon": Icons.shopping_bag,
      "color": Colors.orange,
    },
    {
      "date": "April, 19 2020 12:31",
      "order": "#92287157",
      "amount": "-RM 37.00",
      "icon": Icons.remove_circle,
      "color": Colors.red,
    },
    {
      "date": "April, 19 2020 12:31",
      "order": "#92287157",
      "amount": "-RM 21.00",
      "icon": Icons.shopping_bag,
      "color": Colors.orange,
    },
    {
      "date": "April, 19 2020 12:31",
      "order": "#92287157",
      "amount": "-RM 75.00",
      "icon": Icons.shopping_bag,
      "color": Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        elevation: 0,
        title: const Text(
          "Payment Methods",
          style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),

            // Card Section (Updated to Fit Image)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 170, // ✅ Set fixed height for better image fitting
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
                            "assets/img/debitcard.jpg", // ✅ Card Image fits perfectly
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover, // ✅ Ensures the image fills the container
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.settings, color: Color.fromARGB(255, 255, 152, 0)),
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => const EditCardPage(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              const Text(
                                "••••  ••••  ••••  1579",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "AMANDA",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(179, 0, 0, 0)),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "12/2",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(179, 0, 0, 0)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Add New Card Button
                Container(
                  width: 50,
                  height: 120, // ✅ Matching height with card for proper alignment
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 152, 0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 30),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const AddCardPage(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Transaction List
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: transaction["color"].withOpacity(0.2),
                              child: Icon(transaction["icon"], color: transaction["color"]),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction["date"],
                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                                Text(
                                  "Order ${transaction["order"]}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          transaction["amount"],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: transaction["color"],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
