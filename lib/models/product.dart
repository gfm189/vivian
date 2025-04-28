// lib/models/product.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String shortDescription;
  final String price;
  final String regularPrice;
  final String? salePrice;
  final bool onSale;
  final List<String> images;
  final List<int> categoryIds;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.regularPrice,
    this.salePrice,
    required this.onSale,
    required this.images,
    required this.categoryIds,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract image URLs from the images array
    List<String> imageUrls = [];
    if (json['images'] != null) {
      imageUrls = List<String>.from(
        json['images'].map((image) => image['src'] as String),
      );
    }

    // Extract category IDs
    List<int> categories = [];
    if (json['categories'] != null) {
      categories = List<int>.from(
        json['categories'].map((category) => category['id'] as int),
      );
    }

    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      shortDescription: json['short_description'] as String,
      price: json['price'] as String,
      regularPrice: json['regular_price'] as String? ?? json['price'] as String,
      salePrice: json['sale_price'] as String?,
      onSale: json['on_sale'] as bool? ?? false,
      images: imageUrls,
      categoryIds: categories,
    );
  }
}