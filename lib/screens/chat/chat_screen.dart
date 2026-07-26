import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:logiflow/services/message_service.dart';

final MessageService messageService = MessageService();

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final me = client.auth.currentUser?.id;

      if (me == null) {
        if (!mounted) return;

        setState(() {
          _messages = [];
          _isLoading = false;
        });

        return;
      }

      final msgs = await messageService.getMessagesBetween(
        me,
        widget.receiverId,
      );

      if (!mounted) return;

      setState(() {
        _messages = List<Map<String, dynamic>>.from(msgs);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar mensagens: $e");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    final client = Supabase.instance.client;
    final me = client.auth.currentUser?.id;

    if (me == null) return;

    try {
      await messageService.sendMessage(
        me,
        widget.receiverId,
        text,
      );

      _messageController.clear();

      await _loadMessages();
    } catch (e) {
      debugPrint("Erro ao enviar mensagem: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.receiverName}"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          "No messages yet.\nStart the conversation!",
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];

                          final bool isMe =
                              msg["sender_id"] == currentUserId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: Text(
                                msg["message"]?.toString() ?? "",
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}