class CampsiteReview {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;

  CampsiteReview({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
  });

  factory CampsiteReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final profileImage = user['profileImage'];
    String? imageUrl;
    if (profileImage is Map && profileImage['url'] != null) {
      imageUrl = profileImage['url'];
    } else if (profileImage is String) {
      imageUrl = profileImage;
    }
    return CampsiteReview(
      id: json['id'] ?? '',
      userId: user['id'] ?? '',
      userName: user['name'] ?? '',
      userProfileImageUrl: imageUrl,
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
} 