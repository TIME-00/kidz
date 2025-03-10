import 'package:flutter/material.dart';
import 'checkout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [
    {
      "image": "assets/img/p1.jpg",
      "name": "Babyoye kids shoes",
      "size": "IND 5",
      "price": 80.00,
      "quantity": 1,
      "selected": false, // ✅ Fix: Ensure this key exists
    },
    {
      "image": "assets/img/p2.jpg",
      "name": "Babyhug Half Sleeve",
      "size": "IND 5",
      "price": 80.00,
      "quantity": 1,
      "selected": false,
    },
    {
      "image": "assets/img/p3.jpg",
      "name": "Babyoye kids T-shirt",
      "size": "IND 5",
      "price": 85.00,
      "quantity": 1,
      "selected": false,
    },
  ];

  double shippingFee = 15.00;
  double discount = 0.00;
  TextEditingController couponController = TextEditingController();
  String selectedCoupon = "";

  // Calculate subtotal for selected items
  double getSubtotal() {
    return cartItems
        .where((item) => item["selected"] == true)
        .fold(0.0, (sum, item) => sum + (item["price"] * item["quantity"]));
  }

  double getTotal() {
    double subtotal = getSubtotal();
    return subtotal > 0 ? subtotal + shippingFee - discount : 0.0;
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
        elevation: 0,
        title: const Text(
          "My Cart",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = cartItems[index];

                return Dismissible(
                  key: Key(item["name"]), // Unique key for each item
                  direction: DismissDirection.endToStart, // Swipe left to delete
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12), // Matches cart item spacing
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      cartItems.removeAt(index); // Remove item when dismissed
                    });
                  },
                  child: Container(
                    height: 100, // ✅ Ensures uniform height
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Product Image
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: 80,
                          height: 80,
                          child: Image.asset(item["image"], fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),

                        // Product Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center, // ✅ Align content
                              children: [
                                Text(
                                  item["name"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Size ${item["size"]}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "RM ${item["price"].toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Quantity & Selection
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center, // ✅ Align content
                          children: [
                            // Radio Button (Select/Unselect)
                            IconButton(
                              icon: Icon(
                                item["selected"]
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: const Color.fromARGB(255, 255, 179, 0),
                              ),
                              onPressed: () {
                                setState(() {
                                  item["selected"] = !item["selected"];
                                });
                              },
                            ),
                            Row(
                              children: [
                                // Decrease Quantity Button
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.black),
                                  onPressed: item["quantity"] > 1
                                      ? () {
                                          setState(() {
                                            item["quantity"]--;
                                          });
                                        }
                                      : null,
                                ),
                                Text(
                                  "${item["quantity"]}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                // Increase Quantity Button
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      item["quantity"]++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Coupon Code
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: couponController,
                    decoration: InputDecoration(
                      hintText: "Enter coupon/promocode",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 179, 0),
                  ),
                  onPressed: () {
                    setState(() {
                      if (couponController.text == "DISCOUNT10") {
                        discount = 10.00;
                        selectedCoupon = "DISCOUNT10 Applied";
                      } else {
                        discount = 0.00;
                        selectedCoupon = "Invalid Coupon";
                      }
                    });
                  },
                  child: const Text(
                    "Apply",
                    style: TextStyle(color: Colors.white), // White text
                  ),
                ),
              ],
            ),
          ),
          if (selectedCoupon.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                selectedCoupon,
                style: TextStyle(
                  color: discount > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Order Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                orderSummaryRow("Subtotal", getSubtotal()),
                orderSummaryRow("Shipping Fee", getSubtotal() > 0 ? shippingFee : 0.00),
                const Divider(thickness: 1, color: Colors.black),
                orderSummaryRow("Total", getTotal(), isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Proceed to Buy Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 123, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                List<Map<String, dynamic>> selectedItems =
                    cartItems.where((item) => item["selected"]).toList();
                if (selectedItems.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(cartItems: selectedItems, total: getTotal()),
                    ),
                  );
                }
              },
              child: Text(
                "Proceed to Buy (${cartItems.where((item) => item["selected"]).length} items)",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget orderSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("RM ${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}