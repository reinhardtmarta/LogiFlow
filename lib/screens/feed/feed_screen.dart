import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../ai/gemma_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Widget> _feedItems = [];

  void _handleSend() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    setState(() {
      _feedItems.add(_buildChatBubble(text, isUser: true));
      _controller.clear();
    });

    final response = await AgentService.processUserRequest(text);

    setState(() {
      _feedItems.add(_buildChatBubble(response.text, isUser: false));

      if (response.action == AgentAction.showProduct && response.products != null) {
        for (var prod in response.products!) {
          _feedItems.add(_buildProductCard(prod));
        }
      }
    });
  }

  Widget _buildChatBubble(String text, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        border: Border.all(color: product.isRescue ? Colors.redAccent : Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (product.isRescue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                  child: const Text('RESCUE', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text('📍 ${product.address}', style: const TextStyle(color: Colors.grey)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              Text('Qty: ${product.quantity}', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('View details'),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiFlow Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory),
            tooltip: 'Access Stock',
            onPressed: () {
              // Navigate to stock screen (if implemented)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: _feedItems,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask the agent for help or type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send, color: Colors.green), onPressed: _handleSend),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
