class Review {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? userImage;
  final int rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
  });

  String get displayName {
    final parts = [firstName, lastName].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Người dùng ẩn danh' : parts.join(' ');
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      userImage: json['user_image'],
      rating: (json['rating'] ?? 0).toInt(),
      comment: json['comment'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'user_image': userImage,
      'rating': rating,
      'comment': comment,
      'images': images,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 