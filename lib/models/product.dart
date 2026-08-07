import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Product.fromFirestore(Map<String, dynamic> map) {
    DateTime expiry = DateTime.now();

    final expiryValue = map['expiryDate'];

    if (expiryValue is Timestamp) {
      expiry = expiryValue.toDate();
    } else if (expiryValue is String) {
      expiry = DateTime.tryParse(expiryValue) ?? DateTime.now();
    }

    return Product(
      id: map['id']?.toString(),

      userId: map['userId']?.toString() ?? '',

      name: map['name'] ?? '',

      quantity: map['quantity'] ?? 0,

      price: (map['price'] ?? 0).toDouble(),

      expiryDate: expiry,

      condition: map['condition'] ?? '',

      isProducer: map['isProducer'] ?? false,

      address: map['address'] ?? '',

      imagePath: map['imagePath'],

      category: map['category'] ?? 'Other',

      isRescue: map['isRescue'] ?? false,

      wastePreventedKg:
          (map['wastePreventedKg'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'condition': condition,
      'isProducer': isProducer,
      'address': address,
      'imagePath': imagePath,
      'category': category,
      'isRescue': isRescue,
      'wastePreventedKg': wastePreventedKg,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
