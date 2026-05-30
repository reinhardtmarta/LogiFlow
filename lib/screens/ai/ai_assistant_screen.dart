import 'package:flutter/material.dart';
import '../../core/gemma_service.dart';
import '../../models/user.dart';
import '../../core/database_helper.dart';

class AiAssistantScreen extends StatefulWidget {
  final User user;
  const AiAssistantScreen({super.key, required this.user});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _response = "Ask anything about reducing food waste, promotions, or stock management.\n\nGemma 4 will give you smart suggestions (may download model on first use ~1-2GB).";
  bool _isThinking = false;

  Future<void> _askGemma() async {
    final q = _promptController.text.trim();
    if (q.isEmpty) return;

    setState(() => _isThinking = true);

    final prompt = "You are LogiFlow AI helping reduce food waste.\nUser role: ${widget.user.isSeller ? 'Seller' : 'Consumer'}.\nQuestion: $q\nGive practical advice in 2-4 sentences.";

    final result = await GemmaService.generateResponse(prompt);

    setState(() {
      _response = result;
      _isThinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gemma AI Assistant"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_response, style: const TextStyle(fontSize: 16)),
            ),
            const Spacer(),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: "What should I do with near-expiry milk?",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isThinking ? null : _askGemma,
                icon: const Icon(Icons.psychology),
                label: Text(_isThinking ? "Thinking with Gemma..." : "Ask Gemma 4"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            const Text("Tip: Gemma may download a model on first use.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}