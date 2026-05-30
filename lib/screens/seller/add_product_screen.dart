import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../core/database_helper.dart';
import '../../models/user.dart';

class AddProductScreen extends StatefulWidget {
  final User user;
  const AddProductScreen({super.key, required this.user});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  String _condition = "Fresh";
  bool _isProducer = true;
  String _category = "Fruits & Vegetables";
  bool _isLoading = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    "Fruits & Vegetables",
    "Dairy",
    "Bakery",
    "Meat & Fish",
    "Grains & Pasta",
    "Beverages",
    "Ready Meals",
    "Other"
  ];

  final List<String> _conditions = ["Fresh", "Ripe", "Bakery", "Near Expiry", "Frozen"];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _addProduct() async {
    if (_nameController.text.trim().isEmpty ||
        _qtyController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill name, quantity and price")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final product = Product(
      userId: widget.user.id!,
      name: _nameController.text.trim(),
      quantity: int.tryParse(_qtyController.text) ?? 1,
      price: double.tryParse(_priceController.text) ?? 0.0,
      expiryDate: _expiryDate,
      condition: _condition,
      isProducer: _isProducer,
      address: _addressController.text.trim().isEmpty
          ? "Local Address"
          : _addressController.text.trim(),
      imagePath: _selectedImage?.path,
      category: _category,
    );

    await DatabaseHelper.instance.insertProduct(product);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product published successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Tap to add photo (optional)"),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Product Name *",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price (USD) *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(labelText: "Condition", border: OutlineInputBorder()),
              items: _conditions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _condition = val!),
            ),
            const SizedBox(height: 16),

            ListTile(
              title: const Text("Expiry Date"),
              subtitle: Text("
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _expiryDate = picked);
                },
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Pickup Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text("I am the local producer/farmer"),
              value: _isProducer,
              onChanged: (v) => setState(() => _isProducer = v),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addProduct,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Publish Product", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}