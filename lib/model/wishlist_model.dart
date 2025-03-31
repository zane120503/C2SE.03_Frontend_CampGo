
class Wishlist {
  final String id;
  final String userId;
  final List<WishlistItem> product;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wishlist({
    required this.id,
    required this.userId,
    required this.product,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'],
      userId: json['userId'],
      product: (json['product'] as List)
          .map((item) => WishlistItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class WishlistItem {
  final String id;
  final Product? product;
  final DateTime dateAdded;

  WishlistItem({
    required this.id,
    this.product,
    required this.dateAdded,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      dateAdded: DateTime.parse(json['dateAdded']),
    );
  }
}

// File: lib/model/produt_model.dart
class Product {
  final String id;
  final String name;
  final double? price;
  final String? description;
  final String? category;
  final String? brand;
  final int? stock;
  final double? rating;
  final List<String>? images;

  Product({
    required this.id,
    required this.name,
    this.price,
    this.description,
    this.category,
    this.brand,
    this.stock,
    this.rating,
    this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price']?.toDouble(),
      description: json['description'],
      category: json['category'],
      brand: json['brand'],
      stock: json['stock'],
      rating: json['rating']?.toDouble(),
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : null,
    );
  }
}

// File: lib/model/review_model.dart
class Review {
  final String? id;
  final int rating;
  final List<String> images;
  final String comment;

  Review({
    this.id,
    required this.rating,
    required this.images,
    required this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      images: List<String>.from(json['images']),
      comment: json['comment'],
    );
  }
}