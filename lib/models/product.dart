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

  factory Product.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('user_id') || map.containsKey('qty')) {
      final dynamic uid = map['user_id'];
      final String userIdStr = uid != null ? uid.toString() : '';
      final expiryRaw = map['expiry_date'] as String? ?? DateTime.now().toIso8601String();
      return Product(
        id: map['id'] != null ? map['id'].toString() : null,
        userId: userIdStr,
        name: map['name'] as String? ?? '',
        quantity: (map['qty'] ?? map['quantity'] ?? 0) as int,
        price: ((map['price'] ?? 0) as num).toDouble(),
        expiryDate: DateTime.parse(expiryRaw),
        condition: map['condition'] as String? ?? '',
        isProducer: (map['is_producer'] as int? ?? 0) == 1,
        address: map['address'] as String? ?? '',
        imagePath: map['image_path'] as String?,
        category: map['category'] as String? ?? 'Other',
        isRescue: (map['is_rescue'] as int? ?? 0) == 1,
        wastePreventedKg: (map['waste_prevented_kg'] as num? ?? 0.0).toDouble(),
      );
    }
    return Product.fromSupabase(map);
  }

  factory Product.fromSupabase(Map<String, dynamic> map) {
    Map<String, dynamic>? productNested;
    final productsData = map['products'];
    
    if (productsData is Map) {
      productNested = Map<String, dynamic>.from(productsData);
    } else if (productsData is List && productsData.isNotEmpty) {
      productNested = Map<String, dynamic>.from(productsData[0]);
    } else if (map['product'] is Map) {
      productNested = Map<String, dynamic>.from(map['product']);
    }

    final sellerId = productNested != null ? (productNested['seller_id'] ?? productNested['user_id']) : null;
    final name = productNested != null ? (productNested['name'] ?? '') : (map['name'] ?? '');
    final priceVal = productNested != null ? (productNested['price'] ?? 0) : (map['price'] ?? 0);

    final expiryRaw = map['expiry_date'];
    DateTime expiry = DateTime.now();
    if (expiryRaw != null) {
      try {
        expiry = DateTime.parse(expiryRaw.toString());
      } catch (_) {
        expiry = DateTime.now();
      }
    }

    return Product(
      id: map['id'] != null ? map['id'].toString() : null,
      userId: sellerId != null ? sellerId.toString() : '',
      name: name.toString(),
      quantity: (map['quantity'] ?? map['qty'] ?? 0) as int,
      price: (priceVal as num).toDouble(),
      expiryDate: expiry,
      condition: map['condition'] as String? ?? '',
      isProducer: (productNested != null ? (productNested['is_producer'] ?? 0) : 0) == 1,
      address: (map['address'] ?? (productNested != null ? productNested['address'] : '')) as String? ?? '',
      imagePath: productNested != null ? productNested['image_path'] as String? : null,
      category: productNested != null ? (productNested['category'] as String? ?? 'Other') : 'Other',
      isRescue: ((productNested != null ? productNested['is_rescue'] : null) as int? ?? 0) == 1,
      wastePreventedKg: (map['waste_prevented_kg'] as num? ?? 0.0).toDouble(),
    );
  }

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
