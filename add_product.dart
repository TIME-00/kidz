import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_product.dart';

class SellerAddProductPage extends StatefulWidget {
  const SellerAddProductPage({super.key});

  @override
  State<SellerAddProductPage> createState() => _SellerAddProductPageState();
}

class _SellerAddProductPageState extends State<SellerAddProductPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final productNameController = TextEditingController();
  final productDescriptionController = TextEditingController();
  final productPriceController = TextEditingController(text: "RM "); // ✅ Starts with "RM "

  List<String> selectedSizes = [];
  List<String> selectedColors = [];

  List<File> selectedImagesMobile = [];
  List<Uint8List> selectedImagesWeb = [];

  final List<String> allSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> allColors = [
    'Red', 'Blue', 'Green', 'Yellow', 'Black', 'White', 'Pink', 'Purple', 'Brown', 'Orange'
  ];
  final ImagePicker picker = ImagePicker();
  bool isSubmitting = false;  
  bool isAddingProduct = false;

  List<Map<String, dynamic>> sellerProducts = [];

  @override
  void initState() {
    super.initState();
    fetchSellerProducts();
  }

  /// ✅ Fetch Seller's Products
  Future<void> fetchSellerProducts() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to add a product!")),
      );
      return;
    }

    // ✅ Fetch seller_id where user_id = logged-in user's UID
    final seller = await supabase
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (seller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only registered sellers can add products!")),
      );
      return;
    }

    final sellerId = seller['id']; 
    
    final products = await supabase
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false); 

    setState(() {
      sellerProducts = List<Map<String, dynamic>>.from(products);
    });
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
    final List<dynamic> images = kIsWeb ? selectedImagesWeb : selectedImagesMobile;

    for (var image in images) {
      final imageName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final storagePath = "products/$imageName";

      if (kIsWeb) {
        await supabase.storage.from('product-images').uploadBinary(storagePath, image as Uint8List);
      } else {
        final fileBytes = await (image as File).readAsBytes();
        await supabase.storage.from('product-images').uploadBinary(storagePath, fileBytes);
      }

      final publicUrl = supabase.storage.from('product-images').getPublicUrl(storagePath);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required!")));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("No user logged in.");

      final seller = await supabase.from('sellers').select('id').eq('user_id', user.id).maybeSingle();
      if (seller == null) throw Exception("You must be a registered seller!");

      final sellerId = seller['id'];
      final uploadedImageUrls = await uploadImages();

      await supabase.from('products').insert({
        'seller_id': sellerId, // Correct seller ID
        'product_name': productNameController.text,
        'product_sizes': selectedSizes,
        'product_colors': selectedColors,
        'product_description': productDescriptionController.text,
        'product_price': double.parse(productPriceController.text.replaceAll("RM", "").trim()),
        'product_images': uploadedImageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product added successfully!")));
      setState(() {
        isAddingProduct = false;
        fetchSellerProducts();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ Collapsible "Add Product" Box
            GestureDetector(
              onTap: () => setState(() => isAddingProduct = !isAddingProduct),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    isAddingProduct ? "Hide Product Form" : "Add Product",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (isAddingProduct)
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text("Product Images"),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          children: [
                            ...selectedImagesMobile.map(
                              (image) => ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(image, width: 80, height: 80, fit: BoxFit.cover),
                              ),
                            ),
                            ...selectedImagesWeb.map(
                              (imageBytes) => ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(imageBytes, width: 80, height: 80, fit: BoxFit.cover),
                              ),
                            ),
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.add, size: 40, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        TextFormField(controller: productNameController, decoration: const InputDecoration(labelText: "Product Name")),
                        const SizedBox(height: 20),

                        // ✅ Select Sizes
                        const Text("Select Sizes"),
                        Wrap(
                          spacing: 10,
                          children: allSizes.map((size) {
                            final isSelected = selectedSizes.contains(size);
                            return ChoiceChip(
                              label: Text(size),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  isSelected ? selectedSizes.remove(size) : selectedSizes.add(size);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // ✅ Select Colors (Now Works Like Sizes)
                        const Text("Select Colors", style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 10,
                          children: allColors.map((color) {
                            final isSelected = selectedColors.contains(color);
                            return ChoiceChip(
                              label: Text(color),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  isSelected ? selectedColors.remove(color) : selectedColors.add(color);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: productPriceController,
                          decoration: const InputDecoration(labelText: "Product Price"),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (!value.startsWith("RM ")) {
                              setState(() {
                                productPriceController.text = "RM $value";
                                productPriceController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: productPriceController.text.length),
                                );
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        TextFormField(controller: productDescriptionController, decoration: const InputDecoration(labelText: "Product Description")),
                        const SizedBox(height: 20),

                        ElevatedButton(onPressed: submitProduct, child: isSubmitting ? const CircularProgressIndicator() : const Text("Submit Product")),
                      ],
                    ),
                  ),
                ),
              ),

            // ✅ Display Seller's Products in a Grid
            Expanded(
              child: sellerProducts.isEmpty
                  ? const Center(child: Text("No products found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                  : GridView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 10, 
                        mainAxisSpacing: 10, 
                        childAspectRatio: 0.7,
                      ),
                      itemCount: sellerProducts.length,
                      itemBuilder: (context, index) {
                        final product = sellerProducts[index];
                        final imageUrl = (product['product_images'] as List<dynamic>).isNotEmpty
                            ? product['product_images'][0] 
                            : 'https://via.placeholder.com/150'; 

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductPage(productData: product),
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
  Widget _buildProductCard(Map<String, dynamic> product, String imageUrl) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            child: Image.network(imageUrl, width: double.infinity, height: 170, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['product_name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("RM ${product['product_price']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}