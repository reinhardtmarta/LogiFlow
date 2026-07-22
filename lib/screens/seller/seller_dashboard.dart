import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/product.dart';
import '../../core/database_helper.dart';
import '../../core/gemma_service.dart'; // Certifique-se de que este é o nome do arquivo da classe LogiFkGemmaService
import 'add_product_screen.dart';

class SellerDashboard extends StatefulWidget {
  final User user;
  const SellerDashboard({super.key, required this.user});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  List<Product> _products = [];
  String _gemmaInsight = "Loading smart suggestions from Gemma...";
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
    String productList = products.isNotEmpty 
        ? products.map((p) => '${p.name} (${p.quantity} units, expires ${p.expiryDate.toString().substring(0,10)})').join(', ')
        : "no products";
        
    // 2. Prompt alinhado com as System Instructions da IA (Foco em dados reais, respostas curtas JSON)
    String prompt = "Analyze this stock and alert about near expiry items: $productList";

    try {
      // 3. Chamada correta do método criado na classe LogiFkGemmaService
      final response = await _gemmaService.processQuery(prompt);

      if (mounted) {
        setState(() {
          // O retorno já é um objeto BotResponse decodificado, basta ler o message
          _gemmaInsight = response.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gemmaInsight = "Could not load insights. Structural error.");
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                        Text("${_products.length} items"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_products.isEmpty)
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
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final p = _products[index];
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
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductScreen(user: widget.user)),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
    );
  }
}
