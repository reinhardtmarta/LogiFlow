class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String address;
  final bool isSeller;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.isSeller,
  });

  factory User.fromFirestore(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: '', // Senha nunca deve ser lida do banco por segurança
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      isSeller: data['is_seller'] == true || data['is_seller'] == 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'is_seller': isSeller,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // Compatibilidade com SQLite se necessário
  Map<String, dynamic> toMap() => toFirestore();
  factory User.fromMap(Map<String, dynamic> map) => User.fromFirestore(map['id']?.toString() ?? '', map);
}
