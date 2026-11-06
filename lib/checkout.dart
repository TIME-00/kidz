import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'shipping.dart';
import 'confirmpay.dart';
import 'package:uuid/uuid.dart';
import 'product_image.dart';

/// Builds the `order_items` payload persisted with an order.
///
/// `product_image` holds a real remote URL or `null` — never a local asset
/// path such as [kDefaultProductImageAsset], which would be meaningless to any
/// other consumer of the stored order. The local default is a rendering
/// concern, applied by [productImage] at display time.
List<Map<String, dynamic>> buildOrderItems(
  List<Map<String, dynamic>> cartItems,
) {
  return cartItems
      .map((item) => <String, dynamic>{
            "product_id": item["product_id"],
            "product_name": item["product_name"] ?? "Unknown",
            "quantity": item["quantity"] ?? 1,
            "price": (item["product_price"] as num?)?.toDouble() ?? 0.0,
            "product_image": resolveProductImageUrl(item["product_image"]),
            "color": item["color"] ?? "N/A",
            "size": item["size"] ?? "N/A",
          })
      .toList();
}

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double total;
  final double shippingFee;
  final double discount;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.total,
    required this.shippingFee,
    required this.discount,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final supabase = Supabase.instance.client;
  String selectedAddress = "Fetching address...";
  String selectedPayment = "Kidz Pay Wallet";
  String? selectedCardId;
  List<Map<String, dynamic>> userCards = [];

  @override
  void initState() {
    super.initState();
    fetchUserAddress();
    fetchUserCards();
  }

  Future<void> fetchUserAddress() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('users')
        .select('address, city, postcode')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      setState(() {
        selectedAddress =
            "${response['address']}, ${response['city']} ${response['postcode']}";
      });
    }
  }

  Future<void> fetchUserCards() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('bankingcard')
        .select('id, cardholdername, cardnumber')
        .eq('user_id', user.id);

    setState(() {
      userCards = List<Map<String, dynamic>>.from(response);
    });
  }

  void selectCard() {
    if (userCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No saved cards available!")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          padding: const EdgeInsets.all(10),
          children: userCards.map((card) {
            return ListTile(
              title: Text(
                  "**** **** **** ${card['cardnumber'].substring(card['cardnumber'].length - 4)}"),
              subtitle: Text(card['cardholdername']),
              onTap: () {
                setState(() {
                  selectedCardId = card['id'].toString();
                  selectedPayment = "Card";
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void confirmOrder() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You must be logged in to place an order!")),
      );
      return;
    }

    try {
      final String orderId = const Uuid().v4();
      final String orderDate = DateTime.now().toIso8601String();

      if (selectedAddress == "Fetching address...") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please select a valid delivery address.")),
        );
        return;
      }

      List<Map<String, dynamic>> orderItems = buildOrderItems(widget.cartItems);

      // ✅ Insert order into database
      await supabase.from('orders').insert({
        "id": orderId,
        "user_id": user.id,
        "order_date": orderDate,
        "total_price": widget.total,
        "payment_method": selectedPayment,
        "delivery_address": selectedAddress,
        "status": "Packaging",
        "order_items": jsonEncode(orderItems),
        "order_name": "Order-${DateTime.now().millisecondsSinceEpoch}",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmPaymentPage(
              purchasedCartIds: widget.cartItems.map((e) => e["id"]).toList()),
        ),
      );
    } catch (e) {
      print("❌ Order placement failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order placement failed! Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7B00),
        elevation: 0,
        title: const Text(
          "Checkout",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black),
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
                  const Text("Delivery Address",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFB300),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(selectedAddress),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ShippingAddressPage()),
                      ),
                    ),
                  ),

                  // Payment Method Section
                  const SizedBox(height: 20),
                  const Text("Payment Method",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFB300),
                    ),
                    child: Column(
                      children: [
                        radioTile("Kidz Pay Wallet"),
                        radioTile("Card", onTap: selectCard),
                        radioTile("Cash on Delivery"),
                      ],
                    ),
                  ),

                  // My Items Section
                  const SizedBox(height: 20),
                  const Text("My Items",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    children: widget.cartItems.map((item) {
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: productImage(
                              item["product_image"],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(item["product_name"] ?? "Unknown Product",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "Size: ${item["size"] ?? "N/A"}  |  Color: ${item["color"] ?? "N/A"}"),
                          trailing: Text("x${item["quantity"] ?? 1}"),
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
              color: Color(0xFFFFB300),
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal"),
                    Text(
                        "RM ${(widget.total - widget.shippingFee + widget.discount).toStringAsFixed(2)}"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Shipping Fee"),
                    Text("RM ${widget.shippingFee.toStringAsFixed(2)}"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Discount"),
                    Text("- RM ${widget.discount.toStringAsFixed(2)}"),
                  ],
                ),
                const Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      "RM ${(widget.total).toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7B00),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: confirmOrder,
                  child: const Text("Continue",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget radioTile(String value, {VoidCallback? onTap}) {
    return RadioListTile(
      value: value,
      groupValue: selectedPayment,
      title: Text(value),
      onChanged: (val) {
        setState(() {
          selectedPayment = val.toString();
        });
        if (value == "Card") {
          onTap?.call();
        }
      },
      activeColor: Colors.orange,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
