import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../../screens/chat/chat_screen.dart';

class GeneralFeedScreen extends StatefulWidget {
  final User user;
  const GeneralFeedScreen({super.key, required this.user});

  @override
  State<GeneralFeedScreen> createState() => _GeneralFeedScreenState();
}

class _GeneralFeedScreenState extends State<GeneralFeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiFlow Feed'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(child: Text("No items in the feed yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
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
                          receiverId: p.userId,
                          receiverName: 'Seller',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
