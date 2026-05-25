import 'package:flutter/material.dart';
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
  List<Product> _products = [];
  String _gemmaInsight = "Loading AI insights...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });

    // Gemma dá insights inteligentes
    _generateGemmaInsights(products);
  }

  Future<void> _generateGemmaInsights(List<Product> products) async {
    String prompt = """
You are LogiFlow AI. Analyze these products and give a short, useful summary in English:

${products.map((p) => "- \( {p.name} ( \){p.quantity} units, expires ${p.expiryDate.toString().substring(0,10)})").join("\n")}

Focus on:
- Items near expiry
- Promotion suggestions
- Donation opportunities
- Urgent alerts
""";

    final response = await GemmaService.generateResponse(prompt);
    if (mounted) {
      setState(() => _gemmaInsight = response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogiFlow Feed")),
      body: Column(
        children: [
          // Gemma Insights Card
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
                Text(_gemmaInsight, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final daysLeft = product.expiryDate.difference(DateTime.now()).inDays;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${product.quantity} units • ${product.address}"),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("\\[ {product.price.toStringAsFixed(2)}"),
                              if (daysLeft <= 3)
                                const Chip(label: Text("URGENT", style: TextStyle(fontSize: 10)), backgroundColor: Colors.red),
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
}
