import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';
import '../../services/firebase_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  void _updateQty(Product product, int change) async {
    if (product.id == null) return;
    final newQty = (product.quantity + change).clamp(0, 999);
    await firebaseService.setStock(product.id!, newQty);
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
          body: Center(child: Text("Please login to manage stock")));
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('My Stock Management'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: firebaseService.getSellerProductsStream(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stock = snapshot.data ?? [];

                if (stock.isEmpty) {
                  return const Center(child: Text("No products in stock."));
                }

                return ListView.builder(
                  itemCount: stock.length,
                  itemBuilder: (context, index) {
                    final item = stock[index];
                    final daysLeft =
                        item.expiryDate.difference(DateTime.now()).inDays;
                    final isExpiring = daysLeft <= 3;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isExpiring ? Colors.red[100] : Colors.green[100],
                          child: Icon(Icons.inventory,
                              color: isExpiring ? Colors.red : Colors.green),
                        ),
                        title: Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${item.condition}'),
                            Text(
                              isExpiring
                                  ? '⚠️ $daysLeft days until expiry!'
                                  : 'Expires in $daysLeft days',
                              style: TextStyle(
                                color: isExpiring ? Colors.red : Colors.black54,
                                fontWeight: isExpiring
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _updateQty(item, -1)),
                            Text('${item.quantity}'),
                            IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _updateQty(item, 1)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      color: Colors.grey[100],
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            ['All', 'New', 'Cleaned', 'Packaged', 'Expiring'].map((status) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ActionChip(
              label: Text(status),
              onPressed: () {},
            ),
          );
        }).toList(),
      ),
    );
  }
}
