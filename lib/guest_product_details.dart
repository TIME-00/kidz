import 'package:flutter/material.dart';
import 'product_image.dart';

class GuestProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const GuestProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(product['product_images'] ?? []);
    final String name = product['product_name'] ?? "Unknown Product";
    final double price = (product['product_price'] ?? 0).toDouble();
    final String description =
        product['product_description'] ?? "No description available.";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up,
              color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        title: const Text("Product Details"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            productImage(
              firstProductImageUrl(images),
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("RM ${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text("Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description,
                      style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
