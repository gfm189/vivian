// File: lib/models/product_model.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String shortDescription;
  final String price;
  final String regularPrice;
  final String salePrice;
  final List<String> images;
  final bool onSale;
  final Map<String, dynamic> metadata;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.images,
    required this.onSale,
    required this.metadata,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> productImages = [];
    if (json['images'] != null) {
      productImages = List<String>.from(
        json['images'].map((image) => image['src'] as String),
      );
    }

    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      price: json['price'] ?? '0',
      regularPrice: json['regular_price'] ?? json['price'] ?? '0',
      salePrice: json['sale_price'] ?? '',
      images: productImages,
      onSale: json['on_sale'] ?? false,
      metadata: json['meta_data'] != null
          ? Map<String, dynamic>.fromEntries(
        (json['meta_data'] as List).map(
              (meta) => MapEntry(meta['key'], meta['value']),
        ),
      )
          : {},
    );
  }
}