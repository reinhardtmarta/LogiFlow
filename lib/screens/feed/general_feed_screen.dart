import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/chat/chat_screen.dart';

class GeneralFeedScreen extends StatefulWidget {
  const GeneralFeedScreen({super.key});

  @override
  State<GeneralFeedScreen> createState() => _GeneralFeedScreenState();
}

class _GeneralFeedScreenState extends State<GeneralFeedScreen> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;

    // Query inventory joined with products to get combined view
    final res = await client.from('inventory').select('*, products(*)').order('updated_at', ascending: false).limit(100);

    final List<Product> items = [];
    if (res != null) {
      for (var row in res as List) {
        try {
          items.add(Product.fromSupabase(Map<String, dynamic>.from(row)));
        } catch (_) {
          // skip malformed
        }
      }
    }

    setState(() {
      _products = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiFlow Feed'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  final days = p.expiryDate.difference(DateTime.now()).inDays;
                  final isUrgent = days <= 3;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isUrgent ? Colors.red.shade100 : Colors.green.shade100,
                        child: Icon(isUrgent ? Icons.warning : Icons.eco, color: isUrgent ? Colors.red : Colors.green),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${p.quantity} units • ${p.address}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("$days days left", style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (isUrgent) const Text('RESCUE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              receiverId: p.userId.toString(),
                              receiverName: 'Seller',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
