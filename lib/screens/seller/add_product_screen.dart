import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _isLoading = false;

  Future<void> _addProduct() async {
    if (_nameController.text.isEmpty || _qtyController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final product = Product(
      userId: widget.user.id!,
      name: _nameController.text.trim(),
      quantity: int.parse(_qtyController.text),
      price: double.parse(_priceController.text),
      expiryDate: _expiryDate,
      condition: _condition,
      isProducer: _isProducer,
      address: _addressController.text.trim().isEmpty ? "Local Address" : _addressController.text.trim(),
    );

    await DatabaseHelper.instance.insertProduct(product);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully!")),
      );
      Navigator.pop(context, true); // Retorna para dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: "Price (\$)", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Expiry Date"),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_expiryDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(labelText: "Condition", border: OutlineInputBorder()),
              items: ["Fresh", "Ripe", "Near Expiry", "Good Condition"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _condition = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Address / Pickup Location", border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text("I am a Local Producer"),
              value: _isProducer,
              onChanged: (val) => setState(() => _isProducer = val),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addProduct,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Publish Product"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
