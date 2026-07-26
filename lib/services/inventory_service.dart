import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> listInventoryForProduct(
      String productId) async {
    final res = await _db
        .from('inventory')
        .select()
        .eq('product_id', productId)
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> setStock(
    String productId,
    int quantity, {
    String? location,
    String? address,
  }) async {
    await _db.from('inventory').upsert(
      {
        'product_id': productId,
        'quantity': quantity,
        'location': location,
        'address': address,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'product_id',
    );
  }

  Future<void> changeStock(
    String productId,
    int delta,
  ) async {
    final current = await _db
        .from('inventory')
        .select('quantity')
        .eq('product_id', productId)
        .maybeSingle();

    final currentQty = (current?['quantity'] as int?) ?? 0;

    await _db.from('inventory').upsert(
      {
        'product_id': productId,
        'quantity': currentQty + delta,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'product_id',
    );
  }
}

final inventoryService = InventoryService();