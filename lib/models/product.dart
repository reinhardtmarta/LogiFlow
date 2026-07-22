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
  final String? imagePath;
  final String category;
  final bool isRescue; 
  final double wastePreventedKg;

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
    this.imagePath,
    required this.category,
    this.isRescue = false,
    this.wastePreventedKg = 0.0,
  });

  // Lê do Banco de Dados (Snake_case) e converte para o App (CamelCase)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      quantity: map['qty'] as int,
      price: (map['price'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      condition: map['condition'] as String,
      isProducer: (map['is_producer'] as int) == 1,
      address: map['address'] as String? ?? '',
      imagePath: map['image_path'] as String?,
      category: map['category'] as String? ?? 'Outros',
      isRescue: (map['is_rescue'] as int? ?? 0) == 1,
      wastePreventedKg: (map['waste_prevented_kg'] as num? ?? 0.0).toDouble(),
    );
  }

  // Envia do App (CamelCase) para o Banco de Dados (Snake_case)
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
      'image_path': imagePath,
      'category': category,
      'is_rescue': isRescue ? 1 : 0,
      'waste_prevented_kg': wastePreventedKg,
    };
  }
}
