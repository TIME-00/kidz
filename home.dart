import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart.dart';
import 'orders.dart';
import 'product_details.dart' as details_page;
import 'profile.dart';
import 'notification.dart';
import 'user_provider.dart';

void main() {
  runApp(const MyApp());
}

String getGreeting() {
  int hour = DateTime.now().hour;

  if (hour >= 5 && hour < 12) {
    return "Good Morning!";
  } else if (hour >= 12 && hour < 18) {
    return "Good Afternoon!";
  } else {
    return "Good Evening!";
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  String? userFirstName; // ✅ To store user’s first name
  List<Map<String, dynamic>> products = []; // ✅ To store fetched products
  String selectedFilter = "All";
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchProducts();
    Provider.of<UserProvider>(context, listen: false).fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('users')
        .select('first_name')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      setState(() {
        userFirstName = response['first_name']; // ✅ Store the first name
      });
    }
  }

   // ✅ Fetch All Products
  Future<void> fetchProducts() async {
    final response = await supabase.from('products').select('*');

    setState(() {
      products = List<Map<String, dynamic>>.from(response.map((product) {
        return {
          "id": product["id"], // ✅ Ensure ID is included for fetching details
          "product_name": product["product_name"] ?? "Unknown Product",
          "product_price": product["product_price"] ?? 0.0,
          "product_images": product["product_images"] ?? ["assets/img/placeholder.jpg"],
          "rating": product["rating"] ?? 3, 
          "product_sizes": product["product_sizes"] ?? [], // ✅ Include Sizes
          "product_colors": product["product_colors"] ?? [], // ✅ Include Colors
          "product_description": product["product_description"] ?? "No description available.", // ✅ Include Description
        };
      }));
    });
  }
  
  // Function to filter products
  List<Map<String, dynamic>> getFilteredProducts() {
    List<Map<String, dynamic>> filtered = products;

    // Apply filter logic
    switch (selectedFilter) {
      case "Top Rated":
      case "Top Brands":
        filtered = filtered.where((product) => (product["rating"] ?? 0) > 3).toList(); 
        break;
      case "Under 50":
         filtered = filtered.where((product) => (product["product_price"] ?? 0) < 50).toList();
        break;
      case "50+":
        filtered = filtered.where((product) => (product["product_price"] ?? 0) >= 50).toList();
        break;
    }

    // Apply search logic
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
        product["product_name"]?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false).toList(); // ✅ Fix: Ensure product_name is not null
    }

    return filtered;

  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String userFirstName = userProvider.userData?["first_name"] ?? "User";

    List<Map<String, dynamic>> filteredProducts = getFilteredProducts();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()), // ✅ Navigate to Profile Page
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  "assets/img/babyboy.jpg",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            // ✅ Display greeting and fetched user’s name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getGreeting(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  userFirstName, // ✅ Show fetched name
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black, size: 35),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationPage()),
                  );
                },
              ),
              Positioned(
                right: 5, // ✅ Move closer to the top-right corner
                top: 5,   // ✅ Slightly adjust upwards
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationPage()), // ✅ Navigate to Notification Page
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(209, 255, 0, 0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2), // ✅ Adds a subtle shadow
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20), // ✅ Ensures a circular shape
                    child: const Center(
                      child: Text(
                        "10", // ✅ Notification Count
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 179, 0),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.black45),
                      hintText: "Search here...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Filter Categories
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      categoryChip("All"),
                      categoryChip("Top Rated"),
                      categoryChip("Top Brands"),
                      categoryChip("Under 50"),
                      categoryChip("50+"),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Product Grid View
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredProducts.length,
                    padding: const EdgeInsets.only(bottom: 100), // Space for floating nav bar
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(product: product);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation Bar
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 70,
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [BoxShadow(color: const Color.fromARGB(255, 158, 158, 158), blurRadius: 10, spreadRadius: 2)],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Home Button (Orange when active)
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                          child: bottomNavItem(Icons.home, "Home", isActive: true),
                        ),
                        const SizedBox(width: 50),
                        // Orders Button (Grey when on Home Page)
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const OrdersPage()),
                            );
                          },
                          child: bottomNavItem(Icons.shopping_bag, "Orders", isActive: false),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 7,
                      child: FloatingActionButton(
                        backgroundColor: const Color.fromARGB(255, 179, 0, 211),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CartPage(cartItems: [])), // ✅ Pass an empty list or the actual cart data
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.shopping_cart, size: 28, color: Colors.white),
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Color.fromARGB(255, 255, 123, 0), shape: BoxShape.circle),
                                child: const Text(
                                  "03",
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Category Filter Chips
  Widget categoryChip(String text) {
    bool isSelected = text == selectedFilter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = text;
          });
        },
        child: Chip(
          backgroundColor: isSelected ? const Color.fromARGB(255, 255, 123, 0) : Colors.white,
          label: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? const Color.fromARGB(255, 255, 123, 0) : const Color.fromARGB(255, 158, 158, 158)),
          ),
        ),
      ),
    );
  }

  // Widget for Bottom Navigation Bar Item
  Widget bottomNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? const Color.fromARGB(255, 255, 123, 0) : Colors.grey, size: 28),
        Text(
          label,
          style: TextStyle(color: isActive ? const Color.fromARGB(255, 255, 123, 0) : Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ✅ FIX: Added ProductCard with Heart Animation
class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.7,
      upperBound: 1.2,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      _animationController.forward().then((_) => _animationController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    int starCount = (widget.product["rating"] ?? 3).clamp(1, 5);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => details_page.ProductDetailsPage(product: widget.product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      widget.product["product_images"][0], // ✅ Use first image
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/img/placeholder.jpg'); // ✅ Placeholder if error
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product["product_name"] ?? "Unknown Product",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "RM ${widget.product["product_price"] ?? "N/A"}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < starCount ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Heart Icon at the Top Right
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _toggleFavorite,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey<bool>(isFavorite),
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}