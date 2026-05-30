import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../core/database_helper.dart';
import '../../models/product.dart';
import '../chat/chat_screen.dart';

class GeneralFeedScreen extends StatefulWidget {
  final User user;
  const GeneralFeedScreen({super.key, required this.user});

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
    final all = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LogiFlow Feed"),
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
                          if (isUrgent) const Text("RESCUE", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              currentUser: widget.user,
                              receiverId: p.userId,
                              receiverName: "Seller",
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
