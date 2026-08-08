class Product {
  final String? id;
  final String userId;
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

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      userId: data['seller_id'] ?? data['user_id'] ?? '',
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? data['qty'] ?? 0) as int,
      price: ((data['price'] ?? 0) as num).toDouble(),
      expiryDate: data['expiry_date'] != null 
          ? DateTime.parse(data['expiry_date'].toString()) 
          : DateTime.now(),
      condition: data['condition'] ?? '',
      isProducer: data['is_producer'] == true || data['is_producer'] == 1,
      address: data['address'] ?? '',
      imagePath: data['image_path'],
      category: data['category'] ?? 'Other',
      isRescue: data['is_rescue'] == true || data['is_rescue'] == 1,
      wastePreventedKg: ((data['waste_prevented_kg'] ?? 0.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'seller_id': userId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'expiry_date': expiryDate.toIso8601String(),
      'condition': condition,
      'is_producer': isProducer,
      'address': address,
      'image_path': imagePath,
      'category': category,
      'is_rescue': isRescue,
      'waste_prevented_kg': wastePreventedKg,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
