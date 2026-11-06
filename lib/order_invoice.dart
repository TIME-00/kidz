import 'package:flutter/material.dart';
import 'product_image.dart';

class OrderInvoicePage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderInvoicePage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> orderItems = order["order_items"] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
        title: const Text("Order Invoice",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Date
            Text("Order ID: ${order["id"] ?? "N/A"}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
                "Order Date: ${order["order_date"]?.toString().split("T").first ?? "N/A"}"),

            const SizedBox(height: 10),
            const Divider(),

            // Order Items List
            Expanded(
              child: ListView.builder(
                itemCount: orderItems.length,
                itemBuilder: (context, index) {
                  final item = orderItems[index];
                  final imageUrl = item["product_image"] ?? "";
                  final name = item["product_name"] ?? "Unknown Product";
                  final size = item["size"] ?? "N/A";
                  final color = item["color"] ?? "N/A";
                  final quantity = item["quantity"] ?? 1;
                  final price = item["price"] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: productImage(imageUrl,
                            width: 50, height: 50, fit: BoxFit.cover),
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Size: $size, Color: $color"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("RM ${price.toString()}"),
                          Text("x$quantity"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // Total Price
            Text(
              "Total Price: RM ${order["total_price"]?.toStringAsFixed(2) ?? "0.00"}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            // Payment Method
            Text("Payment Method: ${order["payment_method"] ?? "N/A"}"),
          ],
        ),
      ),
    );
  }
}
