import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'checkout.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  const CartPage({super.key, required this.cartItems});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cartItems = [
    {
      "id": "123",
      "product_name": "Sample Product",
      "product_price": 20.0,
      "product_image": "https://via.placeholder.com/150",
      "size": "M",
      "color": "Red",
      "quantity": 1,
      "selected": false
    }
  ];
  double shippingFee = 15.00;
  double discount = 0.00;
  TextEditingController couponController = TextEditingController();
  String selectedCoupon = "";

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    cartItems = widget.cartItems;
  }

  Future<void> fetchCartItems() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('cart')
        .select('id, product_id, size, color, quantity, products(product_name, product_price, product_images)')
        .eq('user_id', user.id)
        .order('id', ascending: false);

    setState(() {
      cartItems = response.map<Map<String, dynamic>>((item) {
        return {
          "id": item["id"],
          "product_id": item["product_id"],
          "product_name": item["products"]["product_name"] ?? "Unknown Product",
          "product_price": item["products"]["product_price"] ?? 0.0,
          "product_image": (item["products"]["product_images"] != null && item["products"]["product_images"].isNotEmpty)
              ? item["products"]["product_images"][0]
              : "https://via.placeholder.com/150",
          "size": item["size"] ?? "N/A",
          "color": item["color"] ?? "N/A",
          "quantity": item["quantity"] ?? 1,
          "selected": false,
        };
      }).toList();
    });
  }

  Future<void> updateCartItemQuantity(int id, int newQuantity) async {
    if (newQuantity > 0) {
      await supabase.from('cart').update({'quantity': newQuantity}).eq('id', id);
    } else {
      await deleteCartItem(id);
    }
    fetchCartItems();
  }

  Future<void> deleteCartItem(int id) async {
    await supabase.from('cart').delete().eq('id', id);
    fetchCartItems();
  }

  double getSubtotal() {
    return cartItems
        .where((item) => item["selected"] == true)
        .fold(0.0, (sum, item) => sum + (item["product_price"] * item["quantity"]));
  }

  double getTotal() {
    return cartItems
        .where((item) => item["selected"] == true)
        .fold(0.0, (sum, item) => sum + (item["product_price"] * item["quantity"]));
  }

  void proceedToCheckout() {
    List<Map<String, dynamic>> selectedItems =
        cartItems.where((item) => item["selected"] == true).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one item to proceed")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          cartItems: selectedItems.map((item) {
            return {
              "id": item["id"]?.toString() ?? "",
              "product_name": item["product_name"] ?? "Unknown Product",
              "product_price": (item["product_price"] as num?)?.toDouble() ?? 0.0,
              "product_image": item["product_image"] ?? "https://via.placeholder.com/150",
              "size": item["size"] ?? "N/A",
              "color": item["color"] ?? "N/A",
              "quantity": item["quantity"] ?? 1,
            };
          }).toList(),
          total: selectedItems.fold(0.0, (sum, item) => (sum + ((item["product_price"] as num?)?.toDouble() ?? 0.0) * (item["quantity"] ?? 1))),
        ),
      ),
    );
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
            child: cartItems.isEmpty
                ? const Center(child: Text("Your cart is empty!"))
                : ListView.builder(
                    itemCount: cartItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];

                      return Dismissible(
                        key: Key("${item["id"]}-${item["size"]}-${item["color"]}"),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) => deleteCartItem(item["id"]),
                        child: Container(
                          height: 100,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                width: 80,
                                height: 80,
                                child: Image.network(
                                  item["product_image"],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset('assets/img/placeholder.jpg');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item["product_name"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Size: ${item["size"]}  |  Color: ${item["color"]}",
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "RM ${item["product_price"].toStringAsFixed(2)}",
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

                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                                      IconButton(
                                        icon: const Icon(Icons.remove, color: Colors.black),
                                        onPressed: () => updateCartItemQuantity(item["id"], item["quantity"] - 1),
                                      ),
                                      Text(
                                        "${item["quantity"]}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, color: Colors.black),
                                        onPressed: () => updateCartItemQuantity(item["id"], item["quantity"] + 1),
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
          // ✅ Summary Section (Subtotal, Shipping Fee, Total)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _summaryRow("Subtotal", "RM ${getSubtotal().toStringAsFixed(2)}"),
                _summaryRow("Shipping Fee", "RM ${shippingFee.toStringAsFixed(2)}"),
                _summaryRow("Discount", "- RM ${discount.toStringAsFixed(2)}"),
                const Divider(thickness: 1),
                _summaryRow(
                  "Total",
                  "RM ${getTotal().toStringAsFixed(2)}",
                  isBold: true,
                ),
              ],
            ),
          ),
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
                  child: const Text("Apply", style: TextStyle(color: Colors.white)),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
              onPressed: proceedToCheckout,
              child: const Text("Proceed to Checkout", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}