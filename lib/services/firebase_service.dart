import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class FirebaseService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseAuth get auth => _firebaseAuth;
  FirebaseFirestore get db => _db;

  // =====================================================
  // 1. AUTENTICAÇÃO E PERFIL
  // =====================================================

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required bool isSeller,
  }) async {
    final credential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception("Falha ao criar conta.");
    }

    try {
      await saveUserData(user.uid, {
        'uid': user.uid,
        'email': email,
        'name': name,
        'phone': phone,
        'address': address,
        'is_seller': isSeller,

        // Plano inicial
        'plan': 'free',

        // Controle de produtos
        'product_count': 0,
        'product_limit': 10,

        // Controle de fotos
        'photos_per_product': 1,

        // Assinatura
        'subscription_status': 'none',

        'created_at': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      try {
        await user.delete();
      } catch (_) {
        // Se o delete falhar, ainda propagamos o erro original.
      }

      throw Exception(
        "Erro ao criar perfil. Tente novamente.",
      );
    }
  }

  Future<UserCredential> signIn(
    String email,
    String password,
  ) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(
    String uid,
  ) async {
    final doc =
        await _db.collection('profiles').doc(uid).get();

    return doc.exists ? doc.data() : null;
  }

  Future<void> saveUserData(
    String uid,
    Map<String, dynamic> data,
  ) {
    return _db
        .collection('profiles')
        .doc(uid)
        .set(
          data,
          SetOptions(merge: true),
        );
  }

  // =====================================================
  // 2. LIMITES DO USUÁRIO
  // =====================================================

  Future<int> getProductCount(String uid) async {
    final profile = await getUserProfile(uid);

    if (profile == null) {
      return 0;
    }

    final value = profile['product_count'];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  Future<int> getProductLimit(String uid) async {
    final profile = await getUserProfile(uid);

    if (profile == null) {
      return 10;
    }

    final value = profile['product_limit'];

    if (value is num) {
      return value.toInt();
    }

    // Compatibilidade com perfis antigos.
    final plan = profile['plan']?.toString();

    if (plan == 'premium') {
      return 100;
    }

    return 10;
  }

  Future<int> getPhotosPerProduct(String uid) async {
    final profile = await getUserProfile(uid);

    if (profile == null) {
      return 1;
    }

    final value = profile['photos_per_product'];

    if (value is num) {
      return value.toInt();
    }

    if (profile['plan'] == 'premium') {
      return 3;
    }

    return 1;
  }

  Future<bool> canAddProduct(String uid) async {
    final count = await getProductCount(uid);
    final limit = await getProductLimit(uid);

    return count < limit;
  }

  // =====================================================
  // 3. PRODUTOS
  // =====================================================

  /// Cria o produto e incrementa o contador.
  ///
  /// A proteção definitiva do limite deve estar nas
  /// Firestore Security Rules.
  Future<void> addProduct(
    Product product, [
    String? userId,
  ]) async {
    final effectiveUserId =
        userId ?? product.userId;

    if (effectiveUserId != product.userId) {
      throw Exception(
        "Usuário do produto inválido.",
      );
    }

    final productRef =
        _db.collection('products').doc();

    final profileRef =
        _db.collection('profiles')
            .doc(effectiveUserId);

    final batch = _db.batch();

    batch.set(
      productRef,
      product.toFirestore(),
    );

    batch.update(
      profileRef,
      {
        'product_count':
            FieldValue.increment(1),
      },
    );

    await batch.commit();
  }

  /// Feed principal.
  ///
  /// Produtos destacados aparecem primeiro.
  /// Dentro de cada grupo, os que vencem primeiro
  /// aparecem primeiro.
  Stream<List<Product>> getProductsStream() {
    return _db
        .collection('products')
        .orderBy(
          'is_featured',
          descending: true,
        )
        .orderBy(
          'expiry_date',
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Product.fromFirestore(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// Produtos de um vendedor específico.
  Stream<List<Product>> getSellerProductsStream(
    String userId,
  ) {
    return _db
        .collection('products')
        .where(
          'seller_id',
          isEqualTo: userId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Product.fromFirestore(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  // =====================================================
  // 4. ESTOQUE
  // =====================================================

  Future<void> updateProductStock(
    String productId,
    int newQuantity,
  ) async {
    if (newQuantity < 0) {
      throw Exception(
        "Quantidade não pode ser negativa.",
      );
    }

    await _db
        .collection('products')
        .doc(productId)
        .update({
      'quantity': newQuantity,
      'updated_at':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStock(
    String productId,
    int quantity,
  ) {
    return updateProductStock(
      productId,
      quantity,
    );
  }

  // =====================================================
  // 5. EXCLUSÃO DE PRODUTO
  // =====================================================

  /// Remove o produto e reduz o contador do vendedor.
  Future<void> deleteProduct(
    String productId,
  ) async {
    final productRef =
        _db.collection('products')
            .doc(productId);

    final productSnapshot =
        await productRef.get();

    if (!productSnapshot.exists) {
      throw Exception(
        "Produto não encontrado.",
      );
    }

    final data = productSnapshot.data();

    if (data == null) {
      throw Exception(
        "Dados do produto inválidos.",
      );
    }

    final sellerId =
        data['seller_id']?.toString();

    if (sellerId == null ||
        sellerId.isEmpty) {
      throw Exception(
        "Produto sem vendedor.",
      );
    }

    final profileRef =
        _db.collection('profiles')
            .doc(sellerId);

    final batch = _db.batch();

    batch.delete(productRef);

    batch.update(
      profileRef,
      {
        'product_count':
            FieldValue.increment(-1),
      },
    );

    await batch.commit();
  }

  // =====================================================
  // 6. CHAT
  // =====================================================

  String _getChatRoomId(
    String userA,
    String userB,
  ) {
    final participants = [
      userA,
      userB,
    ]..sort();

    return participants.join('_');
  }

  Stream<List<Map<String, dynamic>>>
      getChatMessages(
    String userA,
    String userB,
  ) {
    return _db
        .collection('chats')
        .doc(
          _getChatRoomId(
            userA,
            userB,
          ),
        )
        .collection('messages')
        .orderBy(
          'created_at',
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => doc.data(),
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>>
      getChatStream(
    String userA, [
    String? userB,
  ]) {
    final chatRoomId = userB == null
        ? userA
        : _getChatRoomId(
            userA,
            userB,
          );

    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy(
          'created_at',
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => doc.data(),
              )
              .toList(),
        );
  }

  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String message,
  ) async {
    if (message.trim().isEmpty) {
      throw Exception(
        "Mensagem vazia.",
      );
    }

    final chatRoomId =
        _getChatRoomId(
      senderId,
      receiverId,
    );

    final participants = [
      senderId,
      receiverId,
    ]..sort();

    final batch = _db.batch();

    final newMessageRef = _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    batch.set(
      newMessageRef,
      {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message.trim(),
        'created_at':
            FieldValue.serverTimestamp(),
      },
    );

    final chatRoomRef =
        _db.collection('chats')
            .doc(chatRoomId);

    batch.set(
      chatRoomRef,
      {
        'last_message':
            message.trim(),
        'last_update':
            FieldValue.serverTimestamp(),
        'participants':
            participants,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}


// =====================================================
// INSTÂNCIA GLOBAL
// =====================================================

final firebaseService = FirebaseService();
