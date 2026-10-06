class Product {
  final String id;
  final String userId;
  final String name;
  final int quantity;
  final double price;
  final String expiryDate;
  final String condition;
  final bool isProducer;
  final String address;
  final List<String> imagePaths;
  final String category;
  final bool isRescue;
  final bool isFeatured;
  final bool hidden;
  final double wastePreventedKg;
  final String createdAt;
  final int? distanceMeters;

  Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.expiryDate,
    required this.condition,
    this.isProducer = true,
    required this.address,
    this.imagePaths = const [],
    required this.category,
    this.isRescue = false,
    this.isFeatured = false,
    this.hidden = false,
    this.wastePreventedKg = 1.0,
    required this.createdAt,
    this.distanceMeters,
  });

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      userId: data['user_id'] ?? data['userId'] ?? '',
      name: data['name'] ?? '',
      quantity: (data['quantity'] is int) ? data['quantity'] : int.tryParse('${data['quantity']}') ?? 0,
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : double.tryParse('${data['price']}') ?? 0.0,
      expiryDate: data['expiry_date'] ?? data['expiryDate'] ?? DateTime.now().toIso8601String(),
      condition: data['condition'] ?? 'Fresco',
      isProducer: data['is_producer'] ?? data['isProducer'] ?? true,
      address: data['address'] ?? 'São Paulo, SP',
      imagePaths: (data['image_paths'] is List)
          ? List<String>.from(data['image_paths'])
          : (data['imagePath'] != null ? [data['imagePath'].toString()] : []),
      category: data['category'] ?? 'Geral',
      isRescue: data['is_rescue'] ?? data['isRescue'] ?? false,
      isFeatured: data['is_featured'] ?? data['isFeatured'] ?? false,
      hidden: data['hidden'] ?? false,
      wastePreventedKg: (data['waste_prevented_kg'] is num)
          ? (data['waste_prevented_kg'] as num).toDouble()
          : 1.0,
      createdAt: data['created_at'] ?? data['createdAt'] ?? DateTime.now().toIso8601String(),
      distanceMeters: data['distance_meters'] ?? data['distanceMeters'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'expiry_date': expiryDate,
      'condition': condition,
      'is_producer': isProducer,
      'address': address,
      'image_paths': imagePaths,
      'category': category,
      'is_rescue': isRescue,
      'is_featured': isFeatured,
      'hidden': hidden,
      'waste_prevented_kg': wastePreventedKg,
      'created_at': createdAt,
    };
  }
}
