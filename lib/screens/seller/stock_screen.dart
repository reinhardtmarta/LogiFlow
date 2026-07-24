import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<Product> _stock = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _stock = [];
        _isLoading = false;
      });
      return;
    }

    // Select inventory joined with products where product.seller_id == userId
    final res = await client.from('inventory').select('*, products(*)').eq('products.seller_id', userId).order('updated_at', ascending: false);

    final items = <Product>[];
    if (res != null) {
      for (var row in res as List) {
        try {
          items.add(Product.fromSupabase(Map<String, dynamic>.from(row)));
        } catch (_) {}
      }
    }

    setState(() {
      _stock = items;
      _isLoading = false;
    });
  }

  void _updateQty(Product product, int change) async {
    final newQty = (product.quantity + change).clamp(0, 999);
    // Use inventoryService to set stock (upsert)
    await inventoryService.setStock(product.id!, newQty, location: product.address, address: product.address);
    await _loadStock();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Stock Management'), backgroundColor: Colors.green),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatusFilter(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _stock.length,
                    itemBuilder: (context, index) {
                      final item = _stock[index];
                      final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;
                      final isExpiring = daysLeft <= 3;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isExpiring ? Colors.red[100] : Colors.green[100],
                            child: Icon(Icons.inventory, color: isExpiring ? Colors.red : Colors.green),
                          ),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  fontWeight: isExpiring ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQty(item, -1)),
                              Text('${item.quantity}'),
                              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQty(item, 1)),
                            ],
                          ),
                        ),
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
        children: ['All', 'New', 'Cleaned', 'Packaged', 'Expiring'].map((status) {
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
