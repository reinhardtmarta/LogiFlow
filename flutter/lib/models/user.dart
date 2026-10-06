class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final bool isSeller;
  final String language;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.isSeller = false,
    this.language = 'pt',
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      isSeller: data['is_seller'] ?? data['isSeller'] ?? false,
      language: data['language'] ?? 'pt',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'is_seller': isSeller,
      'language': language,
    };
  }
}
