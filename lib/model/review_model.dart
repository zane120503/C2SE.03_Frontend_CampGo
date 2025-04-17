class Review {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? userImage;
  final int rating;
  final String comment;
  final List<String>? images;
  final DateTime createdAt;
  final String userId;

  Review({
    required this.id,
    this.firstName,
    this.lastName,
    this.userImage,
    required this.rating,
    required this.comment,
    this.images,
    required this.createdAt,
    required this.userId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      userImage: json['user_image'],
      rating: json['rating'],
      comment: json['comment'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'user_image': userImage,
      'rating': rating,
      'comment': comment,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }
} 