/// Entidad de dominio que representa un producto de la API.
/// El mapeo respeta exactamente la estructura del JSON devuelto por
/// GET /products (Regla de negocio de US03: "Mapeo del JSON").
class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final double rating;
  final int ratingCount;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
    required this.ratingCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rating =
        (json['rating'] as Map<String, dynamic>?) ?? const {};

    return Product(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      rating: (rating['rate'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (rating['count'] as num?)?.toInt() ?? 0,
    );
  }
}
