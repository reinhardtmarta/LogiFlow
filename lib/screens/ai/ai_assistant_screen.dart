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
  final List<Map<String, String>> _messages = [];
  bool _isThinking = false;
  bool _isInitializing = true;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _initGemma();
  }

  Future<void> _initGemma() async {
    try {
      await LogiFlowBotService.initialize();
      setState(() => _statusMessage = "");
    } catch (e) {
      setState(() => _statusMessage = "⚠️ Não foi possível conectar. Verifica a API key.");
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _askGemma() async {
    final q = _promptController.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": q});
      _promptController.clear();
      _isThinking = true;
    });

    final prompt = "You are LogiFlow AI helping reduce food waste.\nUser role: ${widget.user.isSeller ? 'Seller' : 'Consumer'}.\nQuestion: $q\nGive practical advice in 2-4 sentences.";

    final result = await GemmaService.generateResponse(prompt);

    setState(() {
      _messages.add({"role": "gemma", "text": result});
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
      body: Column(
        children: [
          // Mensagem de status/erro
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Text(_statusMessage,
                  style: TextStyle(color: Colors.red.shade800)),
            ),

          // Loading inicial
          if (_isInitializing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(width: 12),
                Text("Connecting to Gemma 4..."),
              ]),
            ),

          // Lista de mensagens
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      "Ask anything about reducing\nfood waste 🌱",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.green
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Thinking indicator
          if (_isThinking)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                SizedBox(width: 8),
                Text("Gemma 4 is thinking...",
                    style: TextStyle(color: Colors.grey)),
              ]),
            ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: "What to do with near-expiry milk?",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: 2,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _isThinking ? null : _askGemma(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_isThinking || _isInitializing) ? null : _askGemma,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("Powered by Gemma 4 via OpenRouter",
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
