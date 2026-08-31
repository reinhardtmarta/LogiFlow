import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class FirebaseService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Getters para acesso rápido
  FirebaseAuth get auth => _firebaseAuth;
  FirebaseFirestore get db => _db;

  // --- 1. AUTENTICAÇÃO E GESTÃO DE PERFIL ---

  /// Realiza o cadastro completo: cria o usuário no Auth e o perfil no Firestore.
  /// Implementa o conceito de "Rollback": se o Firestore falhar, o usuário é deletado do Auth.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required bool isSeller,
  }) async {
    // 1. Cria no Firebase Auth
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      try {
        // 2. Cria o documento de perfil no Firestore
        await saveUserData(user.uid, {
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'address': address,
          'is_seller': isSeller,
          'plan': 'free', // Todo novo usuário começa no plano gratuito
          'product_count': 0, // Contador para controle de limite
          'created_at': FieldValue.serverTimestamp(),
        });
        return credential;
      } catch (e) {
        // Se falhar o Firestore, deleta o usuário do Auth para não gerar "usuário fantasma"
        await user.delete();
        throw Exception("Erro ao criar perfil. Tente novamente.");
      }
    } else {
      throw Exception("Falha ao criar conta.");
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('profiles').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> saveUserData(String uid, Map<String, dynamic> data) {
    return _db.collection('profiles').doc(uid).set(data, SetOptions(merge: true));
  }

  // --- 2. GESTÃO DE PRODUTOS (COM LÓGICA DE MONETIZAÇÃO) ---

  /// Adiciona um produto e incrementa o contador de uso do usuário de forma ATÔMICA.
  /// Se o limite de 10 produtos for atingido, o Firebase (via Security Rules) bloqueará o comando.
  Future<void> addProduct(Product product, [String? userId]) async {
    final effectiveUserId = userId ?? product.userId;
    final batch = _db.batch();

    final productRef = _db.collection('products').doc();
    batch.set(productRef, product.toFirestore());

    final profileRef = _db.collection('profiles').doc(effectiveUserId);
    batch.update(profileRef, {
      'product_count': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Retorna o stream de produtos para o Feed, priorizando os itens PREMIUM (is_featured).
  Stream<List<Product>> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('is_featured', descending: true) // PREMIUMS EM CIMA
        .orderBy('expiry_date', descending: false) // Depois, por data de validade
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Retorna apenas os produtos de um vendedor específico.
  Stream<List<Product>> getSellerProductsStream(String userId) {
    return _db
        .collection('products')
        .where('seller_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateProductStock(String productId, int newQuantity) {
    return _db.collection('products').doc(productId).update({
      'quantity': newQuantity,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Alias para updateProductStock - usado na stock_screen
  Future<void> setStock(String productId, int quantity) {
    return updateProductStock(productId, quantity);
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }

  // --- 3. CHAT EM TEMPO REAL (SISTEMA DE SALAS) ---

  /// Gera um ID único para a sala de chat baseado nos dois IDs dos participantes.
  String _getChatRoomId(String userA, String userB) {
    final participants = [userA, userB]..sort();
    return participants.join('_');
  }

  /// Retorna o Stream de mensagens de uma conversa específica.
  Stream<List<Map<String, dynamic>>> getChatMessages(String userA, String userB) {
    return _db
        .collection('chats')
        .doc(_getChatRoomId(userA, userB))
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data().map<String, dynamic>((key, value) => MapEntry(key, value)))
            .toList());
  }

  /// Stream de mensagens de uma sala de chat - usado em chat_screen
  Stream<List<Map<String, dynamic>>> getChatStream(String userA, [String? userB]) {
    final chatRoomId = userB == null ? userA : _getChatRoomId(userA, userB);
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Envia uma mensagem e atualiza o cabeçalho da conversa (para a lista de chats).
  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    final chatRoomId = _getChatRoomId(senderId, receiverId);
    final participants = [senderId, receiverId]..sort();
    
    final batch = _db.batch();

    // 1. Cria a mensagem na subcoleção
    final newMessageRef = _db.collection('chats').doc(chatRoomId).collection('messages').doc();
    batch.set(newMessageRef, {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2. Atualiza o documento da sala (para exibir a "última mensagem" na lista de conversas)
    final chatRoomRef = _db.collection('chats').doc(chatRoomId);
    batch.set(chatRoomRef, {
      'last_message': message,
      'last_update': FieldValue.serverTimestamp(),
      'participants': participants,
    }, SetOptions(merge: true));

    await batch.commit();
  }
}

// Instância global única (Singleton)
final firebaseService = FirebaseService();
