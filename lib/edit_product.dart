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

  List<String> selectedSizes = [];
  List<String> selectedColors = [];

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

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    productNameController =
        TextEditingController(text: widget.productData['product_name']);
    productDescriptionController =
        TextEditingController(text: widget.productData['product_description']);
    productPriceController = TextEditingController(
        text: "RM ${widget.productData['product_price']}");

    selectedSizes = List<String>.from(widget.productData['product_sizes']);
    selectedColors = List<String>.from(widget.productData['product_colors']);
  }

  /// ✅ Delete Product Confirmation Dialog
  Future<void> confirmDeleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text(
            "Are you sure you want to delete this product? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      deleteProduct();
    }
  }

  /// ✅ Delete Product in Supabase
  Future<void> deleteProduct() async {
    setState(() => isSubmitting = true);
    try {
      await supabase
          .from('products')
          .delete()
          .eq('id', widget.productData['id']);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Product deleted successfully!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
    setState(() => isSubmitting = false);
  }

  /// ✅ Update Product in Supabase
  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      await supabase.from('products').update({
        'product_name': productNameController.text.trim(),
        'product_description': productDescriptionController.text.trim(),
        'product_price': double.parse(
            productPriceController.text.replaceAll("RM", "").trim()),
        'product_sizes': selectedSizes,
        'product_colors': selectedColors,
      }).eq('id', widget.productData['id']);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Product updated successfully!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        title: const Text("Edit Product",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: confirmDeleteProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Product Name
                  _buildTextField(productNameController, "Product Name"),
                  const SizedBox(height: 16),

                  // ✅ Product Price
                  _buildTextField(productPriceController, "Product Price"),
                  const SizedBox(height: 16),

                  // ✅ Product Description
                  _buildTextField(
                      productDescriptionController, "Product Description"),
                  const SizedBox(height: 16),

                  // ✅ Select Sizes
                  const Text("Select Sizes",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: allSizes.map((size) {
                      final isSelected = selectedSizes.contains(size);
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSelected,
                        selectedColor: Colors.orange.withOpacity(0.3),
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
                  const SizedBox(height: 16),

                  // ✅ Select Colors
                  const Text("Select Colors",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: allColors.map((color) {
                      final isSelected = selectedColors.contains(color);
                      return ChoiceChip(
                        label: Text(color),
                        selected: isSelected,
                        selectedColor: Colors.orange.withOpacity(0.3),
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
                  const SizedBox(height: 16),

                  // ✅ Update Product Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isSubmitting ? null : updateProduct,
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Update Product",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Common Text Field Widget
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
      validator: (value) => value!.isEmpty ? "Please enter $label" : null,
    );
  }
}
