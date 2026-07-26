import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'package:logiflow/models/product.dart';
import '../chat/chat_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final User user;
  const MarketplaceScreen({super.key, required this.user});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    setState(() {
      // Temporary sample product until real loading logic is implemented
      _products = [
        Product(
          userId: '1',
          name: 'Sample Product',
          quantity: 1,
          price: 1.0,
          expiryDate: DateTime.now().add(const Duration(days: 5)),
          condition: 'Good',
          isProducer: false,
          address: 'Sample Address',
          category: 'Other',
        )
      ];
      _filteredProducts = _products;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = query.isEmpty
          ? _products
          : _products
              .where((p) =>
                  p.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketplace - Rescue Food"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Search products...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text("No products available yet"))
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final daysLeft = product.expiryDate
                              .difference(DateTime.now())
                              .inDays;
                          final isRescue = daysLeft <= 3;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  "Expires in $daysLeft days • \$${product.price.toStringAsFixed(2)}"),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                      "\$${product.price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  if (isRescue)
                                    const Icon(Icons.warning,
                                        color: Colors.red, size: 18),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      receiverId: product.userId.toString(),
                                      receiverName: "Seller",
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
