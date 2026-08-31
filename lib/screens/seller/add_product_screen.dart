import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';

class AddProductScreen extends StatefulWidget {
  final User user;

  const AddProductScreen({
    super.key,
    required this.user,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));

  String _condition = "Fresh";
  bool _isProducer = true;
  String _category = "Fruits & Vegetables";
  bool _isRescue = false;

  bool _isLoading = false;
  bool _loadingPlan = true;

  int _productLimit = 10;
  int _productCount = 0;
  int _photosPerProduct = 1;

  final List<File> _selectedImages = [];

  final List<String> _categories = [
    "Fruits & Vegetables",
    "Dairy",
    "Bakery",
    "Meat & Fish",
    "Grains & Pasta",
    "Beverages",
    "Ready Meals",
    "Other",
  ];

  final List<String> _conditions = [
    "Fresh",
    "Ripe",
    "Bakery",
    "Near Expiry",
    "Frozen",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLimits();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLimits() async {
    try {
      final uid = widget.user.id!;

      final results = await Future.wait<int>([
        firebaseService.getProductCount(uid),
        firebaseService.getProductLimit(uid),
        firebaseService.getPhotosPerProduct(uid),
      ]);

      if (!mounted) return;

      setState(() {
        _productCount = results[0];
        _productLimit = results[1];
        _photosPerProduct = results[2];
        _loadingPlan = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingPlan = false;
      });

      _showMessage(
        "Could not load account limits: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _pickImages() async {
    if (_photosPerProduct <= 0) {
      _showMessage(
        "Your current plan does not allow photos.",
      );
      return;
    }

    final remaining = _photosPerProduct - _selectedImages.length;

    if (remaining <= 0) {
      _showMessage(
        "Your plan allows $_photosPerProduct photo(s) per product.",
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (images.isEmpty || !mounted) return;

      final selected = images.take(remaining);

      setState(() {
        _selectedImages.addAll(
          selected.map((image) => File(image.path)),
        );
      });

      if (images.length > remaining) {
        _showMessage(
          "Only $remaining more photo(s) can be added with your current plan.",
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        "Could not select photos: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _addProduct() async {
    if (_loadingPlan || _isLoading) return;

    final name = _nameController.text.trim();

    final quantity = int.tryParse(
      _qtyController.text.trim(),
    );

    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    if (name.isEmpty ||
        quantity == null ||
        quantity <= 0 ||
        price == null ||
        price < 0) {
      _showMessage(
        "Please enter a valid name, quantity and price.",
      );
      return;
    }

    if (_productCount >= _productLimit) {
      _showLimitDialog();
      return;
    }

    if (_selectedImages.length > _photosPerProduct) {
      _showMessage(
        "Your plan allows only $_photosPerProduct photo(s) per product.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productId = DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrls = await firebaseService.uploadProductImages(
        userId: widget.user.id!,
        productId: productId,
        images: _selectedImages,
      );

      final product = Product(
        id: productId,
        userId: widget.user.id!,
        name: name,
        quantity: quantity,
        price: price,
        expiryDate: _expiryDate,
        condition: _condition,
        isProducer: _isProducer,
        address: _addressController.text.trim().isEmpty
            ? widget.user.address
            : _addressController.text.trim(),
        imagePath: imageUrls.isNotEmpty ? imageUrls.first : null,
        imagePaths: imageUrls,
        category: _category,
        isRescue: _isRescue,
        wastePreventedKg: quantity * 0.5,
      );

      await firebaseService.addProduct(product);

      if (!mounted) return;

      _showMessage(
        "Product published successfully!",
        backgroundColor: Colors.green,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        "Could not publish product: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLimitDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Product limit reached"),
          content: Text(
            "Your current plan allows $_productLimit products.\n\n"
            "You currently have $_productCount products.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Not now"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Upgrade"),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _expiryDate = selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _loadingPlan
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Products: $_productCount / $_productLimit",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImages,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade400,
                        ),
                      ),
                      child: _selectedImages.isEmpty
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text("Tap to add photos"),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 150,
                                        margin: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.file(
                                            _selectedImages[index],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 13,
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                            onPressed: _isLoading
                                                ? null
                                                : () => _removeImage(
                                                      index,
                                                    ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_selectedImages.length} / $_photosPerProduct photos",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    enabled: !_isLoading,
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
                          enabled: !_isLoading,
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
                          enabled: !_isLoading,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _category = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _condition,
                    decoration: const InputDecoration(
                      labelText: "Condition",
                      border: OutlineInputBorder(),
                    ),
                    items: _conditions
                        .map(
                          (condition) => DropdownMenuItem<String>(
                            value: condition,
                            child: Text(condition),
                          ),
                        )
                        .toList(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _condition = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Expiry Date"),
                    subtitle: Text(
                      "${_expiryDate.year}-"
                      "${_expiryDate.month.toString().padLeft(2, '0')}-"
                      "${_expiryDate.day.toString().padLeft(2, '0')}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _isLoading ? null : _selectExpiryDate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    enabled: !_isLoading,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Address",
                      hintText: widget.user.address,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("I am the producer"),
                    value: _isProducer,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _isProducer = value;
                            });
                          },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Food rescue"),
                    subtitle: const Text(
                      "Mark this product as food rescue.",
                    ),
                    value: _isRescue,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _isRescue = value;
                            });
                          },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Publish Product",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
