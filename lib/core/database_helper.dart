import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../models/user.dart';

class FirebaseDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== USERS ====================

  Future<void> saveUser(User user) async {
    await _db
        .collection('users')
        .doc(user.id)
        .set(user.toFirestore());
  }


  Future<User?> getUser(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      return null;
    }

    return User.fromFirestore({
      'id': doc.id,
      ...doc.data()!,
    });
  }


  // ==================== PRODUCTS ====================

  Future<List<Product>> getAllProducts() async {
    final snapshot = await _db
        .collection('products')
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return Product.fromFirestore({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  }


  Future<List<Product>> getUserProducts(String uid) async {
    final snapshot = await _db
        .collection('products')
        .where('userId', isEqualTo: uid)
        .get();

    return snapshot.docs.map((doc) {
      return Product.fromFirestore({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  }


  Future<List<Product>> searchProducts(String query) async {
    final snapshot = await _db
        .collection('products')
        .where('name',
            isGreaterThanOrEqualTo: query)
        .where('name',
            isLessThan: '$query\uf8ff')
        .get();


    return snapshot.docs.map((doc) {
      return Product.fromFirestore({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  }


  Future<void> insertProduct(Product product) async {
    await _db
        .collection('products')
        .add(product.toFirestore());
  }


  Future<void> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('products')
        .doc(id)
        .update(data);
  }


  // ==================== CHAT ====================

  String _chatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return ids.join('_');
  }


  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String message,
  ) async {

    final chatId = _chatId(
      senderId,
      receiverId,
    );


    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }


  Stream<List<Map<String,dynamic>>> getMessages(
    String userA,
    String userB,
  ) {

    final chatId = _chatId(userA, userB);


    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot){

      return snapshot.docs.map((doc){

        return {
          'id': doc.id,
          ...doc.data(),
        };

      }).toList();

    });
  }
}
