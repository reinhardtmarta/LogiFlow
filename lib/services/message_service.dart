import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMessagesBetween(String userA, String userB) async {
    final res = await _db.from('messages').select().or('sender_id.eq.$userA,receiver_id.eq.$userB').order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    await _db.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

final messageService = MessageService();
