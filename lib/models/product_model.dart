class Product {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String address;
  final bool isRescue; // Se é um item de "Resgate/Zero Waste"

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.address,
    this.isRescue = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      address: json['address'] ?? '',
      isRescue: json['is_rescue'] ?? false,
    );
  }
}
