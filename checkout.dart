import 'package:flutter/material.dart';
import 'shipping.dart';
import 'confirmpay.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const CheckoutPage({super.key, required this.cartItems, required this.total});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPayment = "Touch & Go";
  String selectedAddress = "Home, Raffles University Medini";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
        elevation: 0,
        title: const Text(
          "Checkout",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  const SizedBox(height: 10),
                  const Text("Delivery Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 255, 179, 0),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(selectedAddress),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShippingAddressPage()),
                      ),
                    ),
                  ),

                  // Payment Method Section
                  const SizedBox(height: 20),
                  const Text("Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 255, 179, 0),
                    ),
                    child: Column(
                      children: [
                        RadioListTile(
                          value: "Touch & Go",
                          groupValue: selectedPayment,
                          title: const Text("Touch & Go"),
                          onChanged: (value) => setState(() => selectedPayment = value.toString()),
                        ),
                        RadioListTile(
                          value: "Duit Now",
                          groupValue: selectedPayment,
                          title: const Text("Duit Now"),
                          onChanged: (value) => setState(() => selectedPayment = value.toString()),
                        ),
                        RadioListTile(
                          value: "Cash on Delivery",
                          groupValue: selectedPayment,
                          title: const Text("Cash on Delivery"),
                          onChanged: (value) => setState(() => selectedPayment = value.toString()),
                        ),
                      ],
                    ),
                  ),

                  // My Items Section
                  const SizedBox(height: 20),
                  const Text("My Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    children: widget.cartItems.map((item) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(item["image"], width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          title: Text(item["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Size: ${item["size"]}  RM ${item["price"]}"),
                          trailing: Text("x${item["quantity"]}"),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Section (Total Price & Continue Button)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 179, 0),
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Total Price Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("RM ${widget.total.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ],
                ),
                const SizedBox(height: 10),

                // Continue Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 123, 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ConfirmPaymentPage()),
                    );
                  },
                  child: const Text("Continue", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}