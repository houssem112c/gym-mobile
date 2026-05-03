class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int? pointsPrice;
  final String? imageUrl;
  final int stock;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.pointsPrice,
    this.imageUrl,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      pointsPrice: json['pointsPrice'],
      imageUrl: json['imageUrl'],
      stock: json['stock'] ?? 0,
    );
  }
}
