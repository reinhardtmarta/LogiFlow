import '../core/database_helper.dart';
import '../models/product.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();

  factory ProductService() {
    return _instance;
  }

  ProductService._internal();

  /// Carrega TODOS os produtos (marketplace, feed, search usam isso)
  Future<List<Product>> getAllProducts() async {
    return await DatabaseHelper.instance.getAllProducts();
  }

  /// Busca produtos por query (search screen)
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return await DatabaseHelper.instance.searchProducts(query);
  }

  /// Carrega produtos do usuário específico (seller dashboard)
  Future<List<Product>> getUserProducts(int userId) async {
    return await DatabaseHelper.instance.getUserProducts(userId);
  }
}
