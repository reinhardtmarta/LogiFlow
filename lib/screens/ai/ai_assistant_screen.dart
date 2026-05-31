import 'package:flutter/material.dart';
import '../../core/gemma_service.dart';
import '../../models/user.dart';

class AiAssistantScreen extends StatefulWidget {
  final User user;
  const AiAssistantScreen({super.key, required this.user});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _response = "Powered by Gemma 4 via Google AI.\nAsk anything about reducing food waste, promotions, or stock management.";
  bool _isThinking = false;
  bool _isInitializing = true; // 👈 novo

  @override
  void initState() {
    super.initState();
    _initGemma(); // 👈 chama ao abrir a tela
  }

  Future<void> _initGemma() async {
    try {
      await GemmaService.initialize();
    } catch (e) {
      setState(() => _response = "❌ Failed to initialize Gemma 4: $e");
    } finally {
      setState(() => _isInitializing = false);
    }
  }

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
  void dispose() {
    _promptController.dispose();
    GemmaService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gemma 4 AI Assistant"),
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
              child: _isInitializing
                  ? const Row(children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 12),
                      Text("Loading Gemma 4..."),
                    ])
                  : Text(_response, style: const TextStyle(fontSize: 16)),
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
                onPressed: (_isThinking || _isInitializing) ? null : _askGemma,
                icon: const Icon(Icons.psychology),
                label: Text(_isInitializing
                    ? "Loading Gemma 4..."
                    : _isThinking
                        ? "Thinking with Gemma 4..."
                        : "Ask Gemma 4"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            const Text("Powered by Gemma 4 via Google AI",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
