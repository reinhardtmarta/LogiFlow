class Product {
  final int? id;
  final int userId;
  final String name;
  final int quantity;
  final double price;
  final DateTime expiryDate;
  final String condition;
  final bool isProducer;
  final String address;
  final double wastePreventedKg;
  final String? imagePath;
  final String category;           // ← Novo

  Product({
    this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.expiryDate,
    required this.condition,
    required this.isProducer,
    required this.address,
    this.wastePreventedKg = 0.0,
    this.imagePath,
    this.category = "Other",       // ← Novo
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'qty': quantity,
      'price': price,
      'expiry_date': expiryDate.toIso8601String(),
      'condition': condition,
      'is_producer': isProducer ? 1 : 0,
      'address': address,
      'waste_prevented_kg': wastePreventedKg,
      'image_path': imagePath,
      'category': category,                    // ← Novo
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      quantity: map['qty'],
      price: map['price'],
      expiryDate: DateTime.parse(map['expiry_date']),
      condition: map['condition'],
      isProducer: map['is_producer'] == 1,
      address: map['address'],
      wastePreventedKg: map['waste_prevented_kg'] ?? 0.0,
      imagePath: map['image_path'],
      category: map['category'] ?? "Other",     // ← Novo
    );
  }
}
