class Product {
  final String? id;
  final String userId; // can be UUID string from Supabase or numeric string from local DB
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

  // Factory that handles both the local SQLite shape and the Supabase (joined) shape
  factory Product.fromMap(Map<String, dynamic> map) {
    // Local SQLite shape (v2): id int, user_id int, qty, expiry_date as string
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

    // Fallback: try to parse as Supabase joined row where inventory fields are top-level and product details nested
    return Product.fromSupabase(map);
  }

  // Create a Product from a Supabase inventory row joined with products
  factory Product.fromSupabase(Map<String, dynamic> map) {
    // Possible structures:
    // { id: inventory_id, product_id, quantity, expiry_date, address, products: { id, seller_id, name, price, ... } }
    final productNested = map['products'] ?? map['product'] ?? map['products'][0] ?? null;

    final sellerId = productNested != null ? (productNested['seller_id'] ?? productNested['user_id']) : null;
    final name = productNested != null ? (productNested['name'] ?? '') : (map['name'] ?? '');
    final priceVal = productNested != null ? (productNested['price'] ?? 0) : (map['price'] ?? 0);

    final expiryRaw = map['expiry_date'] ?? map['expiry_date'] as String?;
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
      name: name as String,
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
