import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get db => _db;

  /// Faz o registro de um usuário.
  Future<UserCredential> signUp(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Salva os dados iniciais no Firestore
    if (credential.user != null) {
      await saveUserData(credential.user!.uid, {
        'email': email,
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    
    return credential;
  }

  /// Faz login com email e senha.
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Salva ou atualiza dados do usuário na coleção 'profiles'.
  Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('profiles').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Busca o perfil do usuário na coleção 'profiles'.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('profiles').doc(uid).get();
    return doc.data();
  }
  
  /// Busca perfil por email (útil para migração ou buscas específicas)
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    final query = await _db.collection('profiles').where('email', isEqualTo: email).limit(1).get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }
}

// Instância única exportada
final firebaseService = FirebaseService();
