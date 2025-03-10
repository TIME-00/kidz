import 'package:flutter/material.dart';

class OrderInvoicePage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderInvoicePage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    List<dynamic> orderItems = order["order_items"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
        title: const Text("Order Invoice", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Date
            Text("Order ID: ${order["id"]}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Order Date: ${order["order_date"].split("T")[0]}"),

            const SizedBox(height: 10),
            const Divider(),

            // Order Items List
            Expanded(
              child: ListView.builder(
                itemCount: orderItems.length,
                itemBuilder: (context, index) {
                  final item = orderItems[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item["product_image"],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/img/placeholder.jpg');
                          },
                        ),
                      ),
                      title: Text(
                        item["product_name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Size: ${item["size"]}, Color: ${item["color"]}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("RM ${item["product_price"]}"),
                          Text("x${item["quantity"]}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),
            // Total Price
            Text("Total Price: RM ${order["total_price"].toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

            // Payment Method
            Text("Payment Method: ${order["payment_method"]}"),
            const SizedBox(height: 10),

            // Delivery Address
            Text("Delivery Address:", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(order["delivery_address"]),
          ],
        ),
      ),
    );
  }
}