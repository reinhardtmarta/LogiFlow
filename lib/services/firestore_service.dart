import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/user.dart' as models;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USUÁRIOS ---

  /// Salva ou atualiza o perfil do usuário.
  Future<void> saveUserProfile(models.User user) async {
    if (user.id == null) return;
    await _db.collection('profiles').doc(user.id).set(user.toFirestore(), SetOptions(merge: true));
  }

  /// Lê o perfil de um usuário específico.
  Future<models.User?> getUserProfile(String uid) async {
    final doc = await _db.collection('profiles').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return models.User.fromFirestore(doc.id, doc.data()!);
    }
    return null;
  }

  // --- PRODUTOS ---

  /// Stream de todos os produtos para o Marketplace (Tempo Real).
  Stream<List<Product>> getProductsStream() {
    return _db.collection('products')
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Product.fromFirestore(doc.id, doc.data())).toList();
        });
  }

  /// Stream de produtos de um vendedor específico.
  Stream<List<Product>> getSellerProductsStream(String sellerId) {
    return _db.collection('products')
        .where('seller_id', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Product.fromFirestore(doc.id, doc.data())).toList();
        });
  }

  /// Adiciona um novo produto.
  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toFirestore());
  }

  /// Atualiza estoque ou dados de um produto.
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(productId).update({
      ...data,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Deleta um produto.
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // --- MENSAGENS / CHAT ---

  /// Stream de mensagens entre dois usuários.
  Stream<List<Map<String, dynamic>>> getChatStream(String userA, String userB) {
    // Usamos uma lista de participantes ordenada para criar um ID de conversa único ou filtramos
    return _db.collection('messages')
        .where('participants', arrayContains: userA)
        .orderBy('created_at', ascending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => (doc.data()['participants'] as List).contains(userB))
              .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
              .toList();
        });
  }

  /// Envia uma nova mensagem.
  Future<void> sendMessage(String senderId, String receiverId, String text) async {
    await _db.collection('messages').add({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'participants': [senderId, receiverId],
      'message': text,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}

final firestoreService = FirestoreService();
