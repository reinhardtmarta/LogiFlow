import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirebaseService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  auth.FirebaseAuth get auth => _auth;
  FirebaseFirestore get db => _db;

  // --- AUTENTICAÇÃO ---

  Future<auth.UserCredential> signUp(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (credential.user != null) {
      await saveUserData(credential.user!.uid, {
        'email': email,
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    
    return credential;
  }

  Future<auth.UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('profiles').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('profiles').doc(uid).get();
    return doc.data();
  }

  // --- FIRESTORE / PRODUTOS ---

  Stream<List<Product>> getProductsStream() {
    return _db.collection('products')
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList());
  }

  Stream<List<Product>> getSellerProductsStream(String userId) {
    return _db.collection('products')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toFirestore());
  }

  Future<void> setStock(String productId, int quantity) async {
    await _db.collection('products').doc(productId).update({
      'quantity': quantity,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // --- FEED / POSTS ---

  Stream<List<Map<String, dynamic>>> getFeedStream() {
    return _db.collection('feed_posts')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList());
  }

  Future<void> createPost(Map<String, dynamic> data) async {
    await _db.collection('feed_posts').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // --- MENSAGENS / CHAT ---

  Stream<List<Map<String, dynamic>>> getChatStream(String userA, String userB) {
    List<String> participants = [userA, userB];
    participants.sort();
    String chatRoomId = participants.join("_");

    return _db.collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    List<String> participants = [senderId, receiverId];
    participants.sort();
    String chatRoomId = participants.join("_");

    await _db.collection('chats').doc(chatRoomId).collection('messages').add({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
    });

    await _db.collection('chats').doc(chatRoomId).set({
      'last_message': message,
      'last_update': FieldValue.serverTimestamp(),
      'participants': participants,
    }, SetOptions(merge: true));
  }
}

final firebaseService = FirebaseService();
