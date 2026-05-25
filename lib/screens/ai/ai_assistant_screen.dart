import 'package:flutter/material.dart';
import '../../core/gemma_service.dart';
import '../../models/user.dart';
import '../../models/product.dart';
import '../../core/database_helper.dart';

class AiAssistantScreen extends StatefulWidget {
  final User user;
  const AiAssistantScreen({super.key, required this.user});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _response = "Ask me anything about your products, promotions, donations, or waste reduction.";
  bool _isThinking = false;
  List<Product> _userProducts = [];

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    final products = await DatabaseHelper.instance.getUserProducts(widget.user.id!);
    setState(() => _userProducts = products);
  }

  Future<void> _askGemma() async {
    if (_promptController.text.trim().isEmpty) return;

    setState(() => _isThinking = true);

    String context = _userProducts.isNotEmpty 
        ? "My current products: \( {_userProducts.map((p) => " \){p.name} (${p.quantity} units, expires ${p.expiryDate.toString().substring(0,10)})").join(", ")}."
        : "I have no products registered yet.";

    String fullPrompt = """
You are LogiFlow AI, a helpful assistant specialized in reducing food waste.
User: ${widget.user.name}
Role: ${widget.user.isSeller ? "Seller/Producer" : "Consumer"}

Context: $context

Question: ${_promptController.text}

Give a practical, kind and useful answer in English.
""";

    final result = await GemmaService.generateResponse(fullPrompt);

    setState(() {
      _response = result;
      _isThinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ask Gemma 4"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text(
                  "Talk to Gemma",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Text("Get smart suggestions about your products"),
            const SizedBox(height: 20),

            // Área de Resposta
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(_response, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: "Ex: What should I promote today? Which items are near expiry?",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green, size: 32),
                  onPressed: _isThinking ? null : _askGemma,
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              "Examples: \"Suggest discounts\", \"Which products to donate?\", \"Stock advice\"",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
