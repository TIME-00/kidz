import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'product_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_product.dart';
import 'seller_orders.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key, this.client});
  final SupabaseClient? client;

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  late final SupabaseClient supabase =
      widget.client ?? Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final productNameController = TextEditingController();
  final productDescriptionController = TextEditingController();
  final productPriceController = TextEditingController(text: "RM ");
  List<String> selectedSizes = [];
  List<String> selectedColors = [];
  List<File> selectedImagesMobile = [];
  List<Uint8List> selectedImagesWeb = [];
  final List<String> allSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> allColors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Black',
    'White',
    'Pink',
    'Purple',
    'Brown',
    'Orange'
  ];
  final ImagePicker picker = ImagePicker();
  bool isSubmitting = false;
  bool isAddingProduct = false;
  List<Map<String, dynamic>> sellerProducts = [];
  String? sellerId;
  List<dynamic> products = [];
  List<dynamic> orders = [];
  bool isViewingOrders = false;

  @override
  void initState() {
    super.initState();
    fetchSellerProducts();
  }

  /// ✅ Fetch Seller Data & Orders Together
  Future<void> fetchSellerProducts() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You must be logged in to view products!")),
      );
      return;
    }

    try {
      final seller = await supabase
          .from('sellers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (seller == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Only registered sellers can access this page!")),
        );
        return;
      }
      sellerId = seller['id'];
      final productsData = await supabase
          .from('products')
          .select('*')
          .eq('seller_id', sellerId!)
          .order('created_at', ascending: false);
      setState(() {
        sellerProducts = List<Map<String, dynamic>>.from(productsData);
      });
      await fetchOrders();
    } catch (e) {
      print("❌ Error fetching seller products: $e");
    }
  }

  /// ✅ Pick Image from Gallery (Supports Web & Mobile)
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          selectedImagesWeb.add(Uint8List.fromList(imageBytes));
        });
      } else {
        setState(() {
          selectedImagesMobile.add(File(pickedFile.path));
        });
      }
    }
  }

  /// ✅ Upload Images to Supabase Storage & Get URLs
  Future<List<String>> uploadImages() async {
    final List<String> uploadedUrls = [];
    final List<dynamic> images =
        kIsWeb ? selectedImagesWeb : selectedImagesMobile;

    for (var image in images) {
      final imageName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final storagePath = "products/$imageName";

      if (kIsWeb) {
        await supabase.storage
            .from('product-images')
            .uploadBinary(storagePath, image as Uint8List);
      } else {
        final fileBytes = await (image as File).readAsBytes();
        await supabase.storage
            .from('product-images')
            .uploadBinary(storagePath, fileBytes);
      }

      final publicUrl =
          supabase.storage.from('product-images').getPublicUrl(storagePath);
      uploadedUrls.add(publicUrl);
    }

    return uploadedUrls;
  }

  /// ✅ Submit Product to Database
  Future<void> submitProduct() async {
    if (!_formKey.currentState!.validate() ||
        (selectedImagesMobile.isEmpty && selectedImagesWeb.isEmpty) ||
        selectedColors.isEmpty ||
        selectedSizes.isEmpty ||
        productPriceController.text.isEmpty ||
        productPriceController.text.trim() == "RM") {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required!")));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("No user logged in.");

      final seller = await supabase
          .from('sellers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (seller == null) throw Exception("You must be a registered seller!");

      final sellerId = seller['id'];
      final uploadedImageUrls = await uploadImages();

      await supabase.from('products').insert({
        'seller_id': sellerId, // Correct seller ID
        'product_name': productNameController.text,
        'product_sizes': selectedSizes,
        'product_colors': selectedColors,
        'product_description': productDescriptionController.text,
        'product_price': double.parse(
            productPriceController.text.replaceAll("RM", "").trim()),
        'product_images': uploadedImageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully!")));
      setState(() {
        isAddingProduct = false;
        fetchSellerProducts();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isSubmitting = false);
  }

  /// ✅ Fetch Orders Related to Seller's Products
  Future<void> fetchOrders() async {
    if (sellerId == null) return;
    try {
      final response = await SellerOrders(supabase).read();
      if (mounted) setState(() => orders = response);
    } catch (_) {
      if (!mounted) return;
      setState(() => orders = []);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Orders could not be loaded. Try again.')));
    }
  }

  Future<void> updateOrderStatus(
      Map<String, dynamic> order, String status) async {
    try {
      await SellerOrders(supabase).setStatus(order, status);
      await fetchOrders();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Status could not be changed. Refresh and try again.')));
      await fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        title: const Text("Seller Dashboard",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔥 "Add Product" Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () =>
                  setState(() => isAddingProduct = !isAddingProduct),
              child: Text(isAddingProduct ? "Hide Product Form" : "Add Product",
                  style: const TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 10),

            /// 🔥 "Orders Section" Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 123, 255)),
              onPressed: () async {
                setState(() => isViewingOrders = !isViewingOrders);
                if (isViewingOrders) {
                  await fetchOrders(); // 🔥 Fetch orders every time button is clicked
                }
              },
              child: Text(isViewingOrders ? "Hide Orders" : "Orders Section",
                  style: const TextStyle(color: Colors.white)),
            ),

            if (isAddingProduct)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Product Images",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),

                            Wrap(
                              spacing: 10,
                              children: [
                                ...selectedImagesMobile.map(
                                  (image) => ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(image,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                ...selectedImagesWeb.map(
                                  (imageBytes) => ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(imageBytes,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: pickImage,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Icon(Icons.add,
                                        size: 40, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ✅ Product Name
                            _buildTextField(
                                productNameController, "Product Name"),
                            const SizedBox(height: 20),

                            // ✅ Select Sizes
                            const Text("Select Sizes",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8,
                              children: allSizes.map((size) {
                                final isSelected = selectedSizes.contains(size);
                                return ChoiceChip(
                                  label: Text(size),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      isSelected
                                          ? selectedSizes.remove(size)
                                          : selectedSizes.add(size);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // ✅ Select Colors
                            const Text("Select Colors",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8,
                              children: allColors.map((color) {
                                final isSelected =
                                    selectedColors.contains(color);
                                return ChoiceChip(
                                  label: Text(color),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      isSelected
                                          ? selectedColors.remove(color)
                                          : selectedColors.add(color);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // ✅ Product Price
                            TextFormField(
                              controller: productPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText:
                                    "RM 0.00", // ✅ Shows "RM" inside the field instead
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onChanged: (value) {
                                if (!value.startsWith("RM ")) {
                                  setState(() {
                                    productPriceController.text = "RM $value";
                                    productPriceController.selection =
                                        TextSelection.fromPosition(
                                      TextPosition(
                                          offset: productPriceController
                                              .text.length),
                                    );
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            // ✅ Product Description
                            _buildTextField(productDescriptionController,
                                "Product Description"),
                            const SizedBox(height: 20),

                            // ✅ Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  if (!isSubmitting) {
                                    submitProduct();
                                  }
                                },
                                child: isSubmitting
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text("Submit Product",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            /// 🔥 Orders Section (Expands on Click)
            if (isViewingOrders)
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      color: Colors.orange.shade100,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...order["order_items"].map<Widget>((item) {
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 4),
                                leading: productImage(
                                  item["product_image"],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(
                                  item["product_name"] ?? "Unknown Product",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Color: ${item["color"] ?? "N/A"}, Size: ${item["size"] ?? "N/A"}"),
                                    Text("Qty: ${item["quantity"] ?? 1}"),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Status:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                DropdownButton<String>(
                                  value: const [
                                    "Packaging",
                                    "Shipping",
                                    "Delivering"
                                  ].contains(order["status"])
                                      ? order["status"]
                                      : null,
                                  hint: Text(order["status"] as String),
                                  items: ["Packaging", "Shipping", "Delivering"]
                                      .map((status) => DropdownMenuItem(
                                          value: status, child: Text(status)))
                                      .toList(),
                                  onChanged: order["can_update_status"] != true
                                      ? null
                                      : (newStatus) {
                                          if (newStatus != null) {
                                            updateOrderStatus(
                                                Map<String, dynamic>.from(
                                                    order),
                                                newStatus);
                                          }
                                        },
                                ),
                              ],
                            ),
                            if (order["can_update_status"] != true)
                              const Text(
                                  'Shared or changed order status is managed by Admin.'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ✅ Display Seller's Products in a Grid
            Expanded(
              child: sellerProducts.isEmpty
                  ? const Center(
                      child: Text("No products found",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)))
                  : GridView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: sellerProducts.length,
                      itemBuilder: (context, index) {
                        final product = sellerProducts[index];
                        final String? imageUrl =
                            firstProductImageUrl(product['product_images']);

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProductPage(productData: product),
                            ),
                          ),
                          child: _buildProductCard(product, imageUrl),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Build Product Card without Love Icon
  Widget _buildProductCard(Map<String, dynamic> product, String? imageUrl) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            child: productImage(imageUrl,
                width: double.infinity, height: 170, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['product_name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("RM ${product['product_price']}",
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Helper Function to Build Input Fields
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

extension on PostgrestTransformBuilder<PostgrestList> {
  void or(String s) {}
}
