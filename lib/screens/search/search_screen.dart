import 'package:flutter/material.dart';
import '../../core/database_helper.dart';
import '../../models/product.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isSearching = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    final allProducts = await DatabaseHelper.instance.getAllProducts();
    final results = allProducts.where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase())).toList();

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Products")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by product name...",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                ),
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(child: Text("No results found"))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final p = _searchResults[index];
                            return Card(
                              child: ListTile(
                                title: Text(p.name),
                                subtitle: Text("${p.quantity} units • Expires ${p.expiryDate.toString().substring(0,10)}"),
                                trailing: Text("\ \]{p.price}"),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
