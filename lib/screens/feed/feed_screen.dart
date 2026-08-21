import 'package:flutter/material.dart';
import '../../core/gemma_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Widget> _feedItems = [];
  final GemmaService _gemmaService = GemmaService();

  void _handleSend() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    setState(() {
      _feedItems.add(_buildChatBubble(text, isUser: true));
      _controller.clear();
    });

    final response = await _gemmaService.processQuery(text);

    setState(() {
      _feedItems.add(_buildChatBubble(response.message, isUser: false));

      if (response.command == BotCommand.showProduct &&
          response.payload != null) {
        // Here we could fetch the product from a service if needed
        // For now, just show the message
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiFlow Agent'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                      hintText: 'Ask the agent for help...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: _handleSend),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
