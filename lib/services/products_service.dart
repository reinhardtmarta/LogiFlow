import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> listProducts({int limit = 100}) async {
    final res = await _db.from('products').select<List<Map<String, dynamic>>>().order('created_at', ascending: false).limit(limit);
    return res;
  }

  Future<Map<String, dynamic>?> getProduct(String id) async {
    final res = await _db.from('products').select().eq('id', id).maybeSingle();
    return res as Map<String, dynamic>?;
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    data.removeWhere((k, v) => v == null);
    await _db.from('products').insert(data);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> changes) async {
    changes.removeWhere((k, v) => v == null);
    await _db.from('products').update(changes).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _db.from('products').delete().eq('id', id);
  }
}

final productsService = ProductsService();
