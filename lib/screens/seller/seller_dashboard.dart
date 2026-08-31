import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/product.dart';
import '../../services/firebase_service.dart';
import '../../core/gemma_service.dart';
import 'add_product_screen.dart';

class SellerDashboard extends StatefulWidget {
  final User user;
  const SellerDashboard({super.key, required this.user});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final GemmaService _gemmaService = GemmaService();
  String _gemmaInsight = "Loading smart suggestions from Gemma...";

  @override
  void initState() {
    super.initState();
    // Inicia análise quando o primeiro snapshot chegar (feito via StreamBuilder)
  }

  Future<void> _generateGemmaAnalysis(List<Product> products) async {
    if (products.isEmpty) {
      if (mounted) setState(() => _gemmaInsight = "No products yet. Add some to get insights!");
      return;
    }

    String productList = products.map((p) => '${p.name} (${p.quantity} units, expires ${p.expiryDate.toString().substring(0,10)})').join(', ');
    String prompt = "Analyze this stock and alert about near expiry items: $productList";

    try {
      final response = await _gemmaService.processQuery(prompt);
      if (mounted) {
        setState(() {
          _gemmaInsight = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gemmaInsight = "Could not load insights.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Dashboard"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getSellerProductsStream(widget.user.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? [];
          
          // Dispara análise se os dados mudarem (opcional: adicionar debounce)
          _generateGemmaAnalysis(products);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Welcome back, ${widget.user.name}!\nManage your inventory and reduce waste.",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Gemma 4 Intelligence", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16), 
                    child: Text(_gemmaInsight), 
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("My Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("${products.length} items"),
                  ],
                ),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40), 
                      child: Text("No products yet. Tap + to add.")
                    )
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final days = p.expiryDate.difference(DateTime.now()).inDays;
                      return Card(
                        child: ListTile(
                          title: Text(p.name),
                          subtitle: Text("${p.quantity} units • Expires in $days days"),
                          trailing: days <= 5 
                              ? const Icon(Icons.warning_amber, color: Colors.red) 
                              : null,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductScreen(user: widget.user)),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
    );
  }
}
