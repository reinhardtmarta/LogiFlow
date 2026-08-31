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
  final bool isFeatured;
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
    this.isFeatured = false,
    this.wastePreventedKg = 0.0,
  });

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product.fromJson({...data, 'id': id});
  }

  factory Product.fromJson(Map<String, dynamic> data) {
    final rawExpiryDate = data['expiry_date'] ?? data['expiryDate'];
    final parsedExpiryDate = rawExpiryDate == null
        ? null
        : DateTime.tryParse(rawExpiryDate.toString());

    return Product(
      id: data['id']?.toString(),
      userId: (data['seller_id'] ?? data['user_id'] ?? data['userId'] ?? '')
          .toString(),
      name: (data['name'] ?? '').toString(),
      quantity: _toInt(data['quantity'] ?? data['qty']),
      price: _toDouble(data['price']),
      expiryDate: parsedExpiryDate ?? DateTime.now(),
      condition: (data['condition'] ?? '').toString(),
      isProducer: _toBool(data['is_producer'] ?? data['isProducer']),
      address: (data['address'] ?? '').toString(),
      imagePath: (data['image_path'] ?? data['imagePath'])?.toString(),
      category: (data['category'] ?? 'Other').toString(),
      isRescue: _toBool(data['is_rescue'] ?? data['isRescue']),
      isFeatured: _toBool(data['is_featured'] ?? data['isFeatured']),
      wastePreventedKg: _toDouble(
        data['waste_prevented_kg'] ?? data['wastePreventedKg'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static bool _toBool(dynamic value) {
    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true';
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
      'is_featured': isFeatured,
      'waste_prevented_kg': wastePreventedKg,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
