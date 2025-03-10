import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart.dart';
import 'checkout.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final supabase = Supabase.instance.client;
  late Map<String, dynamic> product;
  String selectedSize = '';
  String selectedColor = '';
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  Future<void> addToCart() async {
    if (selectedSize.isEmpty || selectedColor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select size and color")),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existingCartItem = await supabase
        .from('cart')
        .select('*')
        .eq('user_id', user.id)
        .eq('product_id', product["id"])
        .eq('size', selectedSize)
        .eq('color', selectedColor)
        .maybeSingle();

    if (existingCartItem != null) {
      // If product exists, increase quantity
      await supabase
          .from('cart')
          .update({'quantity': existingCartItem['quantity'] + 1})
          .eq('id', existingCartItem['id']);
    } else {
      // Insert new product into cart
      await supabase.from('cart').insert({
        "user_id": user.id,
        "product_id": product["id"],
        "size": selectedSize,
        "color": selectedColor,
        "quantity": 1,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to cart successfully!")),
    );
  }

  void buyNow() {
    if (selectedSize.isEmpty || selectedColor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select size and color")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          cartItems: [
            {
              "id": widget.product["id"]?.toString() ?? "",
              "product_name": widget.product["product_name"] ?? "Unknown Product",
              "product_price": (widget.product["product_price"] as num?)?.toDouble() ?? 0.0,
              "product_image": (widget.product["product_images"] != null && widget.product["product_images"].isNotEmpty)
                  ? widget.product["product_images"][0]
                  : "https://via.placeholder.com/150",
              "size": selectedSize,
              "color": selectedColor,
              "quantity": 1,
            }
          ],
          total: (widget.product["product_price"] as num?)?.toDouble() ?? 0.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> productImages = List<String>.from(product["product_images"] ?? []);
    String productName = product["product_name"] ?? "Unknown Product";
    List<String> productSizes = List<String>.from(product["product_sizes"] ?? []);
    List<String> productColors = List<String>.from(product["product_colors"] ?? []);
    String productDescription = product["product_description"] ?? "No description available.";
    double productPrice = product["product_price"] ?? 0.0;
    int rating = (product["rating"] ?? 3).clamp(1, 5);

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
                        child: Image.network(
                          productImages.isNotEmpty ? productImages[0] : "https://via.placeholder.com/150",
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/img/placeholder.jpg');
                          },
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
                        productImages.length,
                        (index) => GestureDetector(
                          onTap: () {
                            setState(() {
                              productImages.insert(0, productImages.removeAt(index));
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.network(productImages[index], width: 50, height: 50),
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
                        Text(
                          productName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Size Selection
                  if (productSizes.isNotEmpty)
                    _buildSelection("Size", productSizes, selectedSize, (value) {
                      setState(() => selectedSize = value);
                    }),

                  // ✅ Color Selection
                  if (productColors.isNotEmpty)
                    _buildSelection("Color", productColors, selectedColor, (value) {
                      setState(() => selectedColor = value);
                    }),

                  const SizedBox(height: 15),

                  // ✅ Product Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      "Description",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Text(
                      productDescription,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          // ✅ Bottom Bar: Add to Cart & Buy Now
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Price", style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text(
                      "RM ${productPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),

                Row(
                  children: [
                    ElevatedButton(
                      onPressed: addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: const Text("Add to 🛒", style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: buyNow,  // ✅ Now correctly defined
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text("Buy Now", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelection(String title, List<String> options, String selected, Function(String) onSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            children: options.map((option) {
              bool isSelected = selected == option;
              return GestureDetector(
                onTap: () => onSelect(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}