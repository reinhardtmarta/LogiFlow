import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Carrega TODOS os produtos (marketplace, feed, search usam isso)
  Future<List<Product>> getAllProducts() async {
    final query = await _db.collection('products').get();
    return query.docs.map((doc) => Product.fromFirestore(doc.id, doc.data())).toList();
  }

  /// Busca produtos por query (search screen)
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    
    // Nota: Firestore não tem busca por 'LIKE' nativa. 
    // Para uma busca real, seria necessário Algolia ou similar. 
    // Aqui faremos uma busca simples pelo início da string.
    final res = await _db.collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
        
    return res.docs.map((doc) => Product.fromFirestore(doc.id, doc.data())).toList();
  }

  /// Carrega produtos do usuário específico (seller dashboard)
  Future<List<Product>> getUserProducts(String userId) async {
    final query = await _db.collection('products')
        .where('seller_id', isEqualTo: userId)
        .get();
    return query.docs.map((doc) => Product.fromFirestore(doc.id, doc.data())).toList();
  }

  /// Adiciona um novo produto.
  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toFirestore());
  }
}

final productService = ProductService();
