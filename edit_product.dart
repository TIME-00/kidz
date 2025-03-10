import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const EditProductPage({super.key, required this.productData});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController productNameController;
  late TextEditingController productDescriptionController;
  late TextEditingController productPriceController;

  List<String> productImages = [];
  List<File> selectedImagesMobile = [];
  List<Uint8List> selectedImagesWeb = [];
  final ImagePicker picker = ImagePicker();

  List<String> selectedSizes = [];
  List<String> selectedColors = [];

  final List<String> allSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> allColors = [
    'Red', 'Blue', 'Green', 'Yellow', 'Black', 'White', 'Pink', 'Purple', 'Brown', 'Orange'
  ];

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    productNameController = TextEditingController(text: widget.productData['product_name']);
    productDescriptionController = TextEditingController(text: widget.productData['product_description']);
    productPriceController = TextEditingController(text: "RM ${widget.productData['product_price']}");

    productImages = List<String>.from(widget.productData['product_images']);
    selectedSizes = List<String>.from(widget.productData['product_sizes']);
    selectedColors = List<String>.from(widget.productData['product_colors']);
  }

  /// ✅ Pick Image from Gallery
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          selectedImagesWeb.add(imageBytes);
        });
      } else {
        setState(() {
          selectedImagesMobile.add(File(pickedFile.path));
        });
      }
    }
  }

  /// ✅ Upload Images to Supabase Storage
  Future<List<String>> uploadImages() async {
    final List<String> uploadedUrls = List.from(productImages);

    for (var image in selectedImagesMobile) {
      final imageName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final storagePath = "products/$imageName";

      final fileBytes = await image.readAsBytes();
      await supabase.storage.from('product-images').uploadBinary(storagePath, fileBytes);
      uploadedUrls.add(supabase.storage.from('product-images').getPublicUrl(storagePath));
    }

    return uploadedUrls;
  }

  /// ✅ Update Product in Supabase
  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final uploadedImageUrls = await uploadImages();

      await supabase.from('products').update({
        'product_name': productNameController.text,
        'product_description': productDescriptionController.text,
        'product_price': double.parse(productPriceController.text.replaceAll("RM", "").trim()),
        'product_images': uploadedImageUrls,
        'product_sizes': selectedSizes,
        'product_colors': selectedColors,
      }).eq('id', widget.productData['id']);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product updated successfully!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Product Name
              TextFormField(
                controller: productNameController,
                decoration: const InputDecoration(labelText: "Product Name"),
              ),
              const SizedBox(height: 16),

              // ✅ Product Price
              TextFormField(
                controller: productPriceController,
                decoration: const InputDecoration(labelText: "Product Price"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // ✅ Product Description
              TextFormField(
                controller: productDescriptionController,
                decoration: const InputDecoration(labelText: "Product Description"),
              ),
              const SizedBox(height: 16),

              // ✅ Select Sizes
              const Text("Select Sizes", style: TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 16),

              // ✅ Select Colors
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
              const SizedBox(height: 16),

              // ✅ Product Images
              const Text("Product Images", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  ...productImages.map(
                    (imageUrl) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
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

              // ✅ Update Product Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting ? null : updateProduct,
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Product", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}