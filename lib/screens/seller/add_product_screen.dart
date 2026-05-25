import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  String _category = "Fruits & Vegetables";   // Default
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

  // ... (mantenha os métodos _pickImage e _addProduct iguais)

  Future<void> _pickImage() async { /* mesmo código anterior */ }

  Future<void> _addProduct() async { 
    // ... mesmo código, só adicione category no Product:
    final product = Product(
      userId: widget.user.id!,
      name: _nameController.text.trim(),
      quantity: int.parse(_qtyController.text),
      price: double.parse(_priceController.text),
      expiryDate: _expiryDate,
      condition: _condition,
      isProducer: _isProducer,
      address: _addressController.text.trim().isEmpty ? "Local Address" : _addressController.text.trim(),
      imagePath: _selectedImage?.path,
      category: _category,                    // ← Adicionado
    );

    await DatabaseHelper.instance.insertProduct(product);
    // ... resto igual
  }

  @override
  Widget build(BuildContext context) {
    // ... (o resto do build continua igual até o Dropdown de Condition)

    // Substitua o Dropdown de Condition por este novo:
    return Scaffold(
      // ... appBar e body igual
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Foto (mesmo código anterior)...

            // ... campos de nome, qty, price...

            const SizedBox(height: 16),

            // Nova seleção de Categoria
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: _categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              )).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),

            const SizedBox(height: 16),

            // ... resto dos campos (expiry, condition, address, switch)...

          ],
        ),
      ),
    );
  }
}
