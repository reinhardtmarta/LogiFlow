class User {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final bool isSeller;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.isSeller,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'isSeller': isSeller,
    };
  }

  factory User.fromFirestore(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      isSeller: map['isSeller'] ?? false,
    );
  }
}
