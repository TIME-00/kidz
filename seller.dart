import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_product.dart';

class SellerRegisterPage extends StatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  _SellerRegisterPageState createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends State<SellerRegisterPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final ssmController = TextEditingController();
  final companyNameController = TextEditingController();
  final locationController = TextEditingController();
  String? selectedCompanyType;
  String? selectedCategory;

  bool isRegistering = false; // ✅ Prevents multiple submissions

  final companyTypes = ['Enterprise', 'Sdn Bhd', 'Partnership'];
  final categories = ['Kidz Shoes', 'Kidz Bags', 'Kidz Dresses', 'Kidz Play Things'];

  /// ✅ Register the Seller
  Future<void> registerSeller() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isRegistering = true);

  final user = supabase.auth.currentUser;
  if (user == null) {
    print("⚠️ Error: No user logged in.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You must be logged in to register as a seller!")),
    );
    return;
  }

  final userId = user.id;

  try {
    // ✅ Step 1: Check if the user is already a seller
    final existingSeller = await supabase
        .from('sellers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existingSeller != null) {
      print("⚠️ User is already a registered seller.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are already registered as a seller!")),
      );
      setState(() => isRegistering = false);
      return;
    }

    // ✅ Step 2: Register the new seller
    final response = await supabase.from('sellers').insert({
      'user_id': userId,  // ✅ Ensure user_id is explicitly set
      'ssm_number': ssmController.text,
      'company_name': companyNameController.text,
      'company_type': selectedCompanyType,
      'product_type': selectedCategory,
      'location': locationController.text,
    }).select();

    if (response.isNotEmpty) {
      print("✅ Seller registered successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seller registration successful!")),
      );

      // ✅ Redirect to Add Product Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerAddProductPage()),
      );
    } else {
      print("⚠️ Insert failed: No response from Supabase.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong. Please try again.")),
      );
    }
  } catch (e) {
    print("⚠️ Error registering seller: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }

  setState(() => isRegistering = false);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Seller Registration", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputField(ssmController, "SSM Number", Icons.business),
              _buildInputField(companyNameController, "Company Name", Icons.store),
              _buildDropdown("Type of Company", selectedCompanyType, companyTypes, (val) => setState(() => selectedCompanyType = val)),
              _buildDropdown("Product Category", selectedCategory, categories, (val) => setState(() => selectedCategory = val)),
              _buildInputField(locationController, "Company Location", Icons.location_on),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: isRegistering ? null : registerSeller,
                  child: isRegistering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register & Add Product", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: (v) => v!.isEmpty ? "Please enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orange),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField(
        value: value,
        onChanged: onChanged,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (v) => v == null ? "Please select $label" : null,
      ),
    );
  }
}