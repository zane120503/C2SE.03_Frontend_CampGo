class Product {
  final String id;
  final String productName;
  final String description;
  final double originalPrice;    // giá gốc
  final double price;           // giá sau giảm
  final int stockQuantity;
  final String categoryID;
  final String imageURL;
  final String brand;
  final int sold;
  final int discount;
  final DateTime createdAt;
  final double rating;
  final List<dynamic> images;

  // Getters để tương thích với UI
  String get name => productName;
  String get imageUrl => imageURL;
  double get discountPercentage => discount.toDouble();
  int get soldCount => sold;

  Product({
    required this.id,
    required this.productName,
    required this.description,
    required this.originalPrice,
    required this.price,
    required this.stockQuantity,
    required this.categoryID,
    required this.imageURL,
    required this.brand,
    required this.sold,
    required this.discount,
    required this.createdAt,
    this.rating = 0.0,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Xử lý hình ảnh
      String imageUrl = '';
      if (json['images'] != null && json['images'].isNotEmpty) {
        if (json['images'][0] is Map) {
          imageUrl = json['images'][0]['url'] ?? '';
        } else {
          imageUrl = json['images'][0].toString();
        }
      }

      // Nếu không có hình ảnh từ mảng images, thử lấy từ imageURL
      if (imageUrl.isEmpty) {
        imageUrl = json['imageURL']?.toString() ?? '';
      }

      // Đọc giá gốc và giá sau giảm
      final double originalPrice = json['originalPrice'] is int 
          ? (json['originalPrice'] as int).toDouble()
          : json['originalPrice'] is String 
              ? double.parse(json['originalPrice'])
              : (json['originalPrice'] ?? 0.0).toDouble();

      final double price = json['price'] is int 
          ? (json['price'] as int).toDouble()
          : json['price'] is String 
              ? double.parse(json['price'])
              : (json['price'] ?? 0.0).toDouble();

      return Product(
        id: json['_id']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        originalPrice: originalPrice,
        price: price,
        stockQuantity: (json['stockQuantity'] ?? 0).toInt(),
        categoryID: json['categoryID']?.toString() ?? '',
        imageURL: imageUrl,
        brand: json['brand']?.toString() ?? '',
        sold: (json['sold'] ?? 0).toInt(),
        discount: (json['discount'] ?? 0).toInt(),
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        rating: (json['rating'] ?? 0.0).toDouble(),
        images: json['images'] ?? [],
      );
    } catch (e) {
      print('Lỗi khi parse JSON Product: $e');
      return Product(
        id: '',
        productName: '',
        description: '',
        originalPrice: 0.0,
        price: 0.0,
        stockQuantity: 0,
        categoryID: '',
        imageURL: '',
        brand: '',
        sold: 0,
        discount: 0,
        createdAt: DateTime.now(),
        rating: 0.0,
        images: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productName': productName,
      'description': description,
      'originalPrice': originalPrice,
      'price': price,
      'stockQuantity': stockQuantity,
      'categoryID': categoryID,
      'imageURL': imageURL,
      'brand': brand,
      'sold': sold,
      'discount': discount,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'images': images,
    };
  }
} 