import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/product.dart';
import '../../core/database_helper.dart';
import '../../core/gemma_service.dart';
import 'add_product_screen.dart';

class SellerDashboard extends StatefulWidget {
  final User user;
  const SellerDashboard({super.key, required this.user});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  List<Product> _products = [];
  String _gemmaInsight = "Loading Gemma insights...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await DatabaseHelper.instance.getUserProducts(widget.user.id!);
    setState(() {
      _products = products;
      _isLoading = false;
    });

    _generateGemmaAnalysis(products);
  }

  Future<void> _generateGemmaAnalysis(List<Product> products) async {
    String prompt = """
Act as LogiFlow AI Assistant for a seller.

Products:
${products.map((p) => "- ${p.name} | Qty: ${p.quantity} | Expires: ${p.expiryDate.toString().substring(0,10)} | Price: \\[ {p.price}").join("\n")}

Give a practical and useful summary in English including:
- Items near expiry (urgent action needed)
- Promotion or discount suggestions
- Donation opportunities
- Stock control feedback
- General recommendations to reduce waste
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
        title: const Text("Seller Dashboard"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome back, ${widget.user.name}!",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Manage your products and reduce waste"),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Gemma AI Insights
                    const Text("🤖 Gemma 4 Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_gemmaInsight, style: const TextStyle(fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // My Products
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("My Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("${_products.length} items"),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_products.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("You haven't added any products yet."),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final daysLeft = product.expiryDate.difference(DateTime.now()).inDays;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "${product.quantity} units • Expires in $daysLeft days",
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("\ \]{product.price.toStringAsFixed(2)}"),
                                  if (daysLeft <= 5)
                                    const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(user: widget.user),
            ),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
    );
  }
}
