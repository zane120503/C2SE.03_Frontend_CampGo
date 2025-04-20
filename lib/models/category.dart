class Category {
  final String id;
  final String categoryName;
  final String description;
  final String imageURL;

  Category({
    required this.id,
    required this.categoryName,
    required this.description,
    required this.imageURL,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json['_id']?.toString() ?? '',
        categoryName: json['categoryName']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imageURL: json['imageURL']?.toString() ?? '',
      );
    } catch (e) {
      print('Lỗi khi parse JSON Category: $e');
      return Category(
        id: '',
        categoryName: '',
        description: '',
        imageURL: '',
      );
    }
  }
} 