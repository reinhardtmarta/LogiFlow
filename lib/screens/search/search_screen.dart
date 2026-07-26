import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/user.dart';
import '../chat/chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  List<Product> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    final text = query.trim();

    if (text.isEmpty) {
      if (!mounted) return;

      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Simulação de busca - substitua com sua lógica real
      final filtered = <Product>[];

      if (!mounted) return;

      setState(() {
        _results = filtered;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro na pesquisa: $e');

      if (!mounted) return;

      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)?.settings.arguments as User?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Rescue Items"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Search milk, bread, avocado...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          "No results. Try another search.",
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final product = _results[index];

                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              "${product.quantity} units • Expires: ${product.expiryDate.toString().substring(0, 10)}",
                            ),
                            trailing: Text(
                              "\$${product.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: user == null
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          receiverId:
                                              product.userId.toString(),
                                          receiverName: "Seller",
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}