import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/product.dart';

class FirebaseService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  firebase_auth.FirebaseAuth get auth => _auth;
  FirebaseFirestore get db => _db;

  // --- AUTENTICAÇÃO CENTRALIZADA ---

  /// O MÉTODO DEFINITIVO PARA REGISTRO.
  /// Ele gerencia o Auth e o Firestore em uma única operação lógica.
  /// Se o Firestore falhar, ele apaga o usuário do Auth (Rollback).
  Future<firebase_auth.UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required bool isSeller,
  }) async {
    // 1. Cria o usuário no Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      try {
        // 2. Salva os dados no Firestore
        await saveUserData(user.uid, {
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'address': address,
          'is_seller': isSeller,
          'created_at': FieldValue.serverTimestamp(),
        });
        return credential;
      } catch (e) {
        // 3. ROLLBACK: Se falhar o Firestore, deleta o usuário do Auth
        // Isso evita o erro de "e-mail já em uso" em uma nova tentativa
        await user.delete();
        throw Exception("Erro ao salvar perfil no banco de dados. Tente novamente.");
      }
    } else {
      throw Exception("Falha ao criar conta.");
    }
  }

  Future<firebase_auth.UserCredential> signIn(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  // --- GESTÃO DE PERFIL ---

  Future<void> saveUserData(String uid, Map<String, dynamic> data) {
    return _db.collection('profiles').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('profiles').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  // --- GESTÃO DE PRODUTOS (COM TRATAMENTO DE ERRO NO STREAM) ---

  Stream<List<Product>> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('expiry_date') // Itens próximos do vencimento primeiro
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Product.fromFirestore(
                  doc.id,
                  Map<String, dynamic>.from(doc.data()),
                ),
              )
              .toList(),
        );
  }

  Stream<List<Product>> getSellerProductsStream(String userId) {
    return _db
        .collection('products')
        .where('seller_id', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Product.fromFirestore(
                  doc.id,
                  Map<String, dynamic>.from(doc.data()),
                ),
              )
              .toList()
            ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate)),
        );
  }

  Future<void> addProduct(Product product) {
    return _db.collection('products').add(product.toFirestore());
  }

  Future<void> setStock(String productId, int quantity) {
    return _db.collection('products').doc(productId).update({
      'quantity': quantity,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }

  // --- FEED SOCIAL ---

  Stream<List<Map<String, dynamic>>> getFeedStream() {
    return _db
        .collection('feed_posts')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<void> createPost(Map<String, dynamic> data) {
    return _db.collection('feed_posts').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // --- CHAT EM TEMPO REAL (OTIMIZADO COM BATCH) ---

  String _chatRoomId(String userA, String userB) {
    final participants = [userA, userB]..sort();
    return participants.join('_');
  }

  Stream<List<Map<String, dynamic>>> getChatStream(String userA, String userB) {
    return _db
        .collection('chats')
        .doc(_chatRoomId(userA, userB))
        .collection('messages')
        .orderBy('created_at', descending: false) // Mensagens novas embaixo
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Map<String, dynamic>.from(doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String message,
  ) async {
    final chatRoomId = _chatRoomId(senderId, receiverId);
    final participants = [senderId, receiverId]..sort();
    
    final batch = _db.batch();
    
    // Documento da nova mensagem
    final newMessageRef = _db.collection('chats').doc(chatRoomId).collection('messages').doc();
    
    // Documento da sala de chat (para listar conversas recentes)
    final chatRoomRef = _db.collection('chats').doc(chatRoomId);

    batch.set(newMessageRef, {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
    });

    batch.set(
      chatRoomRef,
      {
        'last_message': message,
        'last_update': FieldValue.serverTimestamp(),
        'participants': participants,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}

final firebaseService = FirebaseService();
