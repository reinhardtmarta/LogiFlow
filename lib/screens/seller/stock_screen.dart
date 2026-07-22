import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../core/database_helper.dart';

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
    final items = await DatabaseHelper.instance.getUserProducts(1); // ID do usuário logado
    setState(() {
      _stock = items;
      _isLoading = false;
    });
  }

  void _updateQty(Product product, int change) async {
    final newQty = (product.quantity + change).clamp(0, 999);
    // Correção: Adição do "!" para garantir que o ID não é nulo
    await DatabaseHelper.instance.updateProduct(product.id!, qty: newQty);
    _loadStock(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Stock Management"), backgroundColor: Colors.green),
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
                              Text("Status: ${item.condition}"),
                              Text(
                                isExpiring 
                                  ? "⚠️ $daysLeft days until expiry!" 
                                  // Correção: Variável alterada de $days para $daysLeft
                                  : "Expires in $daysLeft days",
                                style: TextStyle(
                                  color: isExpiring ? Colors.red : Colors.black54, 
                                  fontWeight: isExpiring ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQty(item, -1)),
                              Text("${item.quantity}"),
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
