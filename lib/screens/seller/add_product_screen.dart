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
  State<AddProductScreen> createState() =>
      _AddProductScreenState();
}

class _AddProductScreenState
    extends State<AddProductScreen> {

  final _nameController =
      TextEditingController();

  final _qtyController =
      TextEditingController();

  final _priceController =
      TextEditingController();

  final _addressController =
      TextEditingController();

  final ImagePicker _picker =
      ImagePicker();

  DateTime _expiryDate =
      DateTime.now().add(
        const Duration(days: 7),
      );

  String _condition = "Fresh";
  bool _isProducer = true;
  String _category =
      "Fruits & Vegetables";
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

  // =====================================================
  // CARREGA LIMITES DO USUÁRIO
  // =====================================================

  Future<void> _loadUserLimits() async {
    try {
      final uid = widget.user.id!;

      final results = await Future.wait([
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
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingPlan = false;
      });
    }
  }

  // =====================================================
  // SELEÇÃO DE FOTOS
  // =====================================================

  Future<void> _pickImages() async {
    if (_photosPerProduct <= 0) {
      return;
    }

    final remaining =
        _photosPerProduct -
        _selectedImages.length;

    if (remaining <= 0) {
      _showMessage(
        "Your plan allows $_photosPerProduct "
        "photo(s) per product.",
      );
      return;
    }

    final images =
        await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (images.isEmpty) {
      return;
    }

    final selected =
        images.take(remaining);

    setState(() {
      _selectedImages.addAll(
        selected.map(
          (image) => File(image.path),
        ),
      );
    });

    if (images.length > remaining) {
      _showMessage(
        "Only $remaining more photo(s) "
        "can be added with your current plan.",
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // =====================================================
  // PUBLICAR PRODUTO
  // =====================================================

  Future<void> _addProduct() async {
    if (_loadingPlan) {
      return;
    }

    // -----------------------------
    // Validação
    // -----------------------------

    final name =
        _nameController.text.trim();

    final quantity =
        int.tryParse(
          _qtyController.text.trim(),
        );

    final price =
        double.tryParse(
          _priceController.text
              .trim()
              .replaceAll(',', '.'),
        );

    if (name.isEmpty ||
        quantity == null ||
        quantity <= 0 ||
        price == null ||
        price < 0) {
      _showMessage(
        "Please enter a valid name, "
        "quantity and price.",
      );
      return;
    }

    // -----------------------------
    // Verifica limite localmente
    // -----------------------------

    if (_productCount >= _productLimit) {
      _showLimitDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // -----------------------------
      // Product
      // -----------------------------

      final product =
          Product(
        userId: widget.user.id!,
        name: name,
        quantity: quantity,
        price: price,
        expiryDate: _expiryDate,
        condition: _condition,
        isProducer: _isProducer,

        address:
            _addressController.text
                    .trim()
                    .isEmpty
                ? widget.user.address
                : _addressController.text.trim(),

        // Compatibilidade com produtos antigos.
        imagePath:
            _selectedImages.isNotEmpty
                ? _selectedImages.first.path
                : null,

        // As URLs reais do Firebase Storage
        // serão adicionadas depois do upload.
        imagePaths: const [],

        category: _category,
        isRescue: _isRescue,

        wastePreventedKg:
            quantity * 0.5,
      );

      // -----------------------------
      // Salva produto
      // -----------------------------

      await firebaseService.addProduct(
        product,
      );

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

  // =====================================================
  // LIMITE ATINGIDO
  // =====================================================

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Product limit reached",
          ),
          content: Text(
            "Your current plan allows "
            "$_productLimit products.\n\n"
            "You currently have "
            "$_productCount products.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Not now",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                // Futuramente:
                // abrir SubscriptionScreen
              },
              child: const Text(
                "Upgrade",
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // MENSAGEM
  // =====================================================

  void _showMessage(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            backgroundColor,
      ),
    );
  }

  // =====================================================
  // INTERFACE
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add New Product",
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: _loadingPlan
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),

              child: Column(
                children: [

                  // ===================================
                  // LIMITE
                  // ===================================

                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      "Products: "
                      "$_productCount / "
                      "$_productLimit",
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ===================================
                  // FOTOS
                  // ===================================

                  GestureDetector(
                    onTap: _pickImages,

                    child: Container(
                      height: 180,
                      width: double.infinity,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey[200],
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        border:
                            Border.all(
                          color: Colors
                              .grey
                              .shade400,
                        ),
                      ),

                      child:
                          _selectedImages
                                  .isEmpty
                              ? const Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Icon(
                                      Icons
                                          .add_a_photo,
                                      size: 48,
                                      color:
                                          Colors.grey,
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      "Tap to add photos",
                                    ),
                                  ],
                                )
                              : Padding(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    8,
                                  ),
                                  child:
                                      ListView
                                          .builder(
                                    scrollDirection:
                                        Axis.horizontal,
                                    itemCount:
                                        _selectedImages
                                            .length,
                                    itemBuilder:
                                        (
                                      context,
                                      index,
                                    ) {
                                      return Stack(
                                        children: [
                                          Container(
                                            width:
                                                150,
                                            margin:
                                                const EdgeInsets
                                                    .only(
                                              right:
                                                  8,
                                            ),
                                            child:
                                                ClipRRect(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                10,
                                              ),
                                              child:
                                                  Image.file(
                                                _selectedImages[
                                                    index],
                                                fit: BoxFit
                                                    .cover,
                                              ),
                                            ),
                                          ),

                                          Positioned(
                                            top:
                                                5,
                                            right:
                                                13,
                                            child:
                                                CircleAvatar(
                                              radius:
                                                  15,
                                              backgroundColor:
                                                  Colors
                                                      .black54,
                                              child:
                                                  IconButton(
                                                padding:
                                                    EdgeInsets
                                                        .zero,
                                                icon:
                                                    const Icon(
                                                  Icons
                                                      .close,
                                                  size:
                                                      18,
                                                  color:
                                                      Colors.white,
                                                ),
                                                onPressed:
                                                    () =>
                                                        _removeImage(
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

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    "${_selectedImages.length} / "
                    "$_photosPerProduct photos",
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ===================================
                  // NOME
                  // ===================================

                  TextField(
                    controller:
                        _nameController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Product Name *",
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ===================================
                  // QUANTIDADE / PREÇO
                  // ===================================

                  Row(
                    children: [

                      Expanded(
                        child: TextField(
                          controller:
                              _qtyController,
                          keyboardType:
                              TextInputType
                                  .number,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Quantity *",
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: TextField(
                          controller:
                              _priceController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Price (USD) *",
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ===================================
                  // CATEGORIA
                  // ===================================

                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        _category,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Category",
                      border:
                          OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (category) =>
                              DropdownMenuItem(
                            value:
                                category,
                            child:
                                Text(
                              category,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value !=
                          null) {
                        setState(
                          () =>
                              _category =
                                  value,
                        );
                      }
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ===================================
                  // CONDIÇÃO
                  // ===================================

        
