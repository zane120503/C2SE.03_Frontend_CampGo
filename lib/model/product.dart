class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageURL;
  final String categoryId;
  final int stockQuantity;
  final double rating;
  final int reviewCount;
  final int discount;
  final int sold;
  final String? brand;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageURL,
    required this.categoryId,
    required this.stockQuantity,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.discount = 0,
    this.sold = 0,
    this.brand,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['productName'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageURL: json['imageURL'] ?? '',
      categoryId: json['categoryID'] ?? '',
      stockQuantity: json['stockQuantity'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      discount: json['discount'] ?? 0,
      sold: json['sold'] ?? 0,
      brand: json['brand'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productName': name,
      'description': description,
      'price': price,
      'imageURL': imageURL,
      'categoryID': categoryId,
      'stockQuantity': stockQuantity,
      'rating': rating,
      'review_count': reviewCount,
      'discount': discount,
      'sold': sold,
      'brand': brand,
    };
  }
} 