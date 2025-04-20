class Product {
  final String id;
  final String productName;
  final String description;
  final double price;          // giá gốc (originalPrice từ backend)
  final double discountedPrice; // giá đã giảm (price từ backend)
  final int stockQuantity;
  final String categoryID;
  final String imageURL;
  final String brand;
  final int sold;
  final int discount;
  final DateTime createdAt;
  final double rating;

  // Getters để tương thích với UI
  String get name => productName;
  String get imageUrl => imageURL;
  double get discountPercentage => discount.toDouble();
  int get soldCount => sold;

  Product({
    required this.id,
    required this.productName,
    required this.description,
    required this.price,
    required this.discountedPrice,
    required this.stockQuantity,
    required this.categoryID,
    required this.imageURL,
    required this.brand,
    required this.sold,
    required this.discount,
    required this.createdAt,
    this.rating = 0.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Đọc giá gốc từ originalPrice
      final double originalPrice = json['originalPrice'] is int 
          ? (json['originalPrice'] as int).toDouble()
          : json['originalPrice'] is String 
              ? double.parse(json['originalPrice'])
              : (json['originalPrice'] ?? 0.0).toDouble();

      // Đọc giá đã giảm từ price
      final double finalPrice = json['price'] is int 
          ? (json['price'] as int).toDouble()
          : json['price'] is String 
              ? double.parse(json['price'])
              : (json['price'] ?? 0.0).toDouble();

      return Product(
        id: json['_id']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: originalPrice,           // giá gốc
        discountedPrice: finalPrice,    // giá đã giảm
        stockQuantity: (json['stockQuantity'] ?? 0).toInt(),
        categoryID: json['categoryID']?.toString() ?? '',
        imageURL: json['imageURL']?.toString() ?? '',
        brand: json['brand']?.toString() ?? '',
        sold: (json['sold'] ?? 0).toInt(),
        discount: (json['discount'] ?? 0).toInt(),
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        rating: (json['rating'] ?? 0.0).toDouble(),
      );
    } catch (e) {
      print('Lỗi khi parse JSON Product: $e');
      return Product(
        id: '',
        productName: '',
        description: '',
        price: 0.0,
        discountedPrice: 0.0,
        stockQuantity: 0,
        categoryID: '',
        imageURL: '',
        brand: '',
        sold: 0,
        discount: 0,
        createdAt: DateTime.now(),
        rating: 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productName': productName,
      'description': description,
      'originalPrice': price,
      'price': discountedPrice,
      'stockQuantity': stockQuantity,
      'categoryID': categoryID,
      'imageURL': imageURL,
      'brand': brand,
      'sold': sold,
      'discount': discount,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
    };
  }
} 