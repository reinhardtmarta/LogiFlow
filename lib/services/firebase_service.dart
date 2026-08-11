import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/product.dart';

class FirebaseService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  firebase_auth.FirebaseAuth get auth => _auth;
  FirebaseFirestore get db => _db;

  Future<firebase_auth.UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
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

  Future<firebase_auth.UserCredential> signIn(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> saveUserData(String uid, Map<String, dynamic> data) {
    return _db.collection('profiles').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('profiles').doc(uid).get();
    return doc.data();
  }

  Stream<List<Product>> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('expiry_date')
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

  String _chatRoomId(String userA, String userB) {
    final participants = [userA, userB]..sort();
    return participants.join('_');
  }

  Stream<List<Map<String, dynamic>>> getChatStream(String userA, String userB) {
    return _db
        .collection('chats')
        .doc(_chatRoomId(userA, userB))
        .collection('messages')
        .orderBy('created_at')
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
    final chat = _db.collection('chats').doc(chatRoomId);
    final newMessage = chat.collection('messages').doc();

    batch.set(newMessage, {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.set(
      chat,
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
