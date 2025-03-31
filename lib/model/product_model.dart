class ProductDimensions {
  final double? width;
  final double? depth;
  final double? height;

  ProductDimensions({
    this.width,
    this.depth,
    this.height,
  });

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      width: json['width']?.toDouble(),
      depth: json['depth']?.toDouble(),
      height: json['height']?.toDouble(),
    );
  }
}

class ProductColor {
  final String? primary;
  final String? secondary;

  ProductColor({
    this.primary,
    this.secondary,
  });

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    return ProductColor(
      primary: json['primary'],
      secondary: json['secondary'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final int discountPercentage;
  final double rating;
  final int soldCount;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.soldCount,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? '',
        price: json['price'] is double ? json['price'] : double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
        discountPercentage: json['discountPercentage'] is int ? json['discountPercentage'] : int.tryParse(json['discountPercentage']?.toString() ?? '') ?? 0,
        rating: json['rating'] is double ? json['rating'] : double.tryParse(json['rating']?.toString() ?? '') ?? 0.0,
        soldCount: json['soldCount'] is int ? json['soldCount'] : int.tryParse(json['soldCount']?.toString() ?? '') ?? 0,
        category: json['category']?.toString() ?? '',
      );
    } catch (e) {
      print('Lỗi khi parse JSON: $e');
      return Product(
        id: 0,
        name: '',
        imageUrl: '',
        price: 0.0,
        discountPercentage: 0,
        rating: 0.0,
        soldCount: 0,
        category: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'soldCount': soldCount,
      'category': category,
    };
  }
} 