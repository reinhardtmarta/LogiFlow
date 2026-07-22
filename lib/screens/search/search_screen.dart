import 'package:flutter/material.dart';
import '../../core/database_helper.dart';
import '../../models/product.dart';
import '../chat/chat_screen.dart';
import '../../models/user.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Product> _results = [];
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final all = await DatabaseHelper.instance.getAllProducts();
    final filtered = all.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
    setState(() {
      _results = filtered;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)?.settings.arguments as User?;

    return Scaffold(
      appBar: AppBar(title: const Text("Search Rescue Items")),
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
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text("No results. Try another search."))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final p = _results[i];
                          return ListTile(
                            title: Text(p.product),
                            subtitle: Text("${p.quantity} units • Expires: ${p.expiryDate.toString().substring(0,10)}"),
                            trailing: Text("\$${p.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: user == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          currentUser: user,
                                          receiverId: p.userId,
                                          receiverProduct: "Seller",
                                        ),
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
