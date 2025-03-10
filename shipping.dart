import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShippingAddressPage extends StatefulWidget {
  const ShippingAddressPage({super.key});

  @override
  _ShippingAddressPageState createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  final supabase = Supabase.instance.client;
  String selectedCountry = "Malaysia";
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();

  bool isLoading = true;
  bool hasChanges = false;

  String originalCountry = "Malaysia";
  String originalAddress = "";
  String originalCity = "";
  String originalPostcode = "";

  @override
  void initState() {
    super.initState();
    fetchShippingAddress();

    // Listen for changes in input fields
    addressController.addListener(checkForChanges);
    cityController.addListener(checkForChanges);
    postcodeController.addListener(checkForChanges);
  }

  /// ✅ Fetch shipping address from Supabase
  Future<void> fetchShippingAddress() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('users')
        .select('country, address, city, postcode')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      setState(() {
        selectedCountry = response['country'] ?? "Malaysia";
        addressController.text = response['address'] ?? "";
        cityController.text = response['city'] ?? "";
        postcodeController.text = response['postcode'] ?? "";

        // ✅ Store original values for comparison
        originalCountry = selectedCountry;
        originalAddress = addressController.text;
        originalCity = cityController.text;
        originalPostcode = postcodeController.text;

        isLoading = false;
      });
    }
  }

  /// ✅ Check if there are any changes
  void checkForChanges() {
    setState(() {
      hasChanges = (selectedCountry != originalCountry ||
          addressController.text != originalAddress ||
          cityController.text != originalCity ||
          postcodeController.text != originalPostcode);
    });
  }


  /// ✅ Save shipping address to Supabase
  Future<void> saveAddress() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('users').update({
      'country': selectedCountry,
      'address': addressController.text.trim(),
      'city': cityController.text.trim(),
      'postcode': postcodeController.text.trim(),
    }).eq('id', user.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shipping address updated successfully!")),
    );

    // ✅ Update original values after saving
    setState(() {
      originalCountry = selectedCountry;
      originalAddress = addressController.text;
      originalCity = cityController.text;
      originalPostcode = postcodeController.text;
      hasChanges = false; // Disable button after saving
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
        elevation: 0,
        title: const Text(
          "Shipping Address",
          style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const Text(
                    "Kidz will deliver your order to this address",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Country Selection
                  const Text("Country", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return ListView(
                            children: ["Malaysia", "Singapore", "Indonesia"]
                                .map((country) => ListTile(
                                      title: Text(country),
                                      onTap: () {
                                        setState(() {
                                          selectedCountry = country;
                                          checkForChanges();
                                        });
                                        Navigator.pop(context);
                                      },
                                    ))
                                .toList(),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedCountry,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Address Input
                  const Text("Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  _buildTextField(addressController),

                  const SizedBox(height: 15),

                  // ✅ City Input
                  const Text("Town / City", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  _buildTextField(cityController),

                  const SizedBox(height: 15),

                  // ✅ Postcode Input
                  const Text("Postcode", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  _buildTextField(postcodeController),

                  const SizedBox(height: 30),

                  // ✅ Save Changes Button (Enable only if there are changes)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasChanges ? Colors.orange : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: hasChanges ? saveAddress : null,
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// ✅ Helper Function to Build TextFields
  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      onChanged: (value) => checkForChanges(), // ✅ Detect changes when typing
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.orange,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}