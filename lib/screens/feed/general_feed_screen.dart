import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/database_helper.dart';
import '../../core/gemma_service.dart';
import '../../models/product.dart';
import '../../models/user.dart';

class GeneralFeedScreen extends StatefulWidget {
  final User user;
  const GeneralFeedScreen({super.key, required this.user});

  @override
  State<GeneralFeedScreen> createState() => _GeneralFeedScreenState();
}

class _GeneralFeedScreenState extends State<GeneralFeedScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _gemmaInsight = "Loading Gemma insights...";
  bool _isLoading = true;

  // Filtros
  String? _selectedCategory;
  final List<String> _categories = [
    "All",
    "Fruits & Vegetables",
    "Dairy",
    "Bakery",
    "Meat & Fish",
    "Grains & Pasta",
    "Beverages",
    "Ready Meals",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
      _isLoading = false;
    });

    _generateGemmaInsights(products);
  }

  void _applyFilter() {
    setState(() {
      if (_selectedCategory == null || _selectedCategory == "All") {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((p) => p.category == _selectedCategory)
            .toList();
      }
    });
  }

  Future<void> _generateGemmaInsights(List<Product> products) async {
    String prompt = """
You are LogiFlow AI. Give a short and useful summary of these products:

${products.map((p) => "- \( {p.name} ( \){p.quantity} units, expires ${p.expiryDate.toString().substring(0,10)})").join("\n")}

Focus on urgent items, promotion ideas and waste reduction tips.
""";

    final response = await GemmaService.generateResponse(prompt);
    if (mounted) {
      setState(() => _gemmaInsight = response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LogiFlow Feed"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Gemma Insights
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Gemma 4 Insights", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_gemmaInsight),
              ],
            ),
          ),

          // Filtros por Categoria
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat || (cat == "All" && _selectedCategory == null);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                        _applyFilter();
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.green[100],
                    ),
                  );
                },
              ),
            ),
          ),

          // Lista de Produtos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text("No products found"))
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final daysLeft = product.expiryDate.difference(DateTime.now()).inDays;
                            final isUrgent = daysLeft <= 3;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.imagePath != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Image.file(
                                        File(product.imagePath!),
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, size: 60, color: Colors.grey),
                                    ),

                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            ),
                                            Chip(
                                              label: Text(product.category),
                                              backgroundColor: Colors.green[100],
                                            ),
                                          ],
                                        ),
                                        Text("📍 ${product.address}"),
                                        Text("📦 ${product.quantity} units"),
                                        Text("💰 \$${product.price.toStringAsFixed(2)}"),
                                        Text(
                                          "Expires in $daysLeft days",
                                          style: TextStyle(
                                            color: isUrgent ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                            Container(
                                              height: 180,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image, size: 50),
                                            ),
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.image, size: 60, color: Colors.grey),
                                      ),
                                    ),

                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (isUrgent)
                                              const Chip(
                                                label: Text("URGENT", style: TextStyle(fontSize: 12)),
                                                backgroundColor: Colors.red,
                                                labelStyle: TextStyle(color: Colors.white),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text("📍 ${product.address}"),
                                        Text("📦 ${product.quantity} units available"),
                                        Text("💰 \$${product.price.toStringAsFixed(2)}"),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Expires in $daysLeft days",
                                          style: TextStyle(
                                            color: isUrgent ? Colors.red : Colors.grey[700],
                                            fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Go to 'My Space' to add products")),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
