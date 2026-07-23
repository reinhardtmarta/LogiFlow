import 'package:supabase_flutter/supabase_flutter.dart';

class FeedService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> listPosts({int limit = 100}) async {
    final res = await _db.from('feed_posts').select().order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> createPost(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toUtc().toIso8601String();
    await _db.from('feed_posts').insert(data);
  }

  Future<void> deletePost(String id) async {
    await _db.from('feed_posts').delete().eq('id', id);
  }
}

final feedService = FeedService();
