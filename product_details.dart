import 'package:flutter/material.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required Map<String, dynamic> product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int selectedSize = 0;
  int selectedColor = 0;
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Product Image & Favorite Button
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[200],
                        child: Image.asset(
                          "assets/img/p1.jpg", // Example image
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 20,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 60,
                        child: IconButton(
                          icon: const Icon(Icons.share, color: Colors.black, size: 28),
                          onPressed: () {
                            // Share functionality (to be implemented)
                          },
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.black,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // ✅ Thumbnail Images
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => GestureDetector(
                          onTap: () {
                            setState(() {
                              // Change main image (if images are different)
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset("assets/img/p1.jpg", width: 50, height: 50),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ✅ Product Name & Rating
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Babyoye kids shoes",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            Icon(Icons.star_half, color: Colors.amber, size: 20),
                            SizedBox(width: 5),
                            Text("4", style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Size Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Size", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(
                            4,
                            (index) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedSize = index;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selectedSize == index ? Colors.blue : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Inch ${index + 5}",
                                  style: TextStyle(
                                    color: selectedSize == index ? const Color.fromARGB(255, 0, 0, 0) : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Color Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Color", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(
                            4,
                            (index) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = index;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: [Colors.red, Colors.blue, Colors.orange, Colors.black][index],
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: selectedColor == index ? const Color.fromARGB(255, 111, 111, 111) : const Color.fromARGB(0, 255, 255, 255),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ✅ Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      "Description",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: const Text(
                      "The sole should be strong and sturdy, and the upper part of the shoe should be made of a material that can withstand wear and tear. Breathability: Good shoes should be breathable to prevent your feet from sweating and smelling..",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),

                  // ✅ Free Delivery
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: const [
                        Text("Free Delivery", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Spacer(),
                        Text("By Saturday, 20th Aug", style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ✅ Product Details Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      "Product Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 179, 0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow("Material", "Rubber + Mesh"),
                        _buildDetailRow("MOQ", "30 pairs for wholesale"),
                        _buildDetailRow("Transport", "Polybag/Box"),
                        _buildDetailRow("Elements", "Breathable"),
                        _buildDetailRow("Closure pattern", "Slip-on"),
                      ],
                    ),
                  ),
                  
                  // ✅ Cash on Delivery & Return Policy
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 179, 0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                "Cash on Delivery",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // ✅ White Text
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 179, 0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                "30 Days Return",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // ✅ White Text
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Bottom Bar: Price, Add to Cart, Buy Now (Floating & Circular)
          Positioned(
            bottom: 20, // ✅ Adjusted for better floating effect
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50), // ✅ Circular shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ Price Section
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Price", style: TextStyle(fontSize: 14, color: Colors.black54)),
                      Text(
                        "RM 80.00",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 140, 255)),
                      ),
                    ],
                  ),

                  // ✅ Add to Cart Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 123, 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text("Add to 🛒", style: TextStyle(fontSize: 16)),
                  ),

                  // ✅ Buy Now Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 255, 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Buy Now", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: $value",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white54, thickness: 1), // ✅ Divider line
        ],
      ),
    );
  }
}
