import 'user_model.dart';  // Thêm import UserProfile

class CampsiteReview {
  final String id;
  final String userId;
  final String userName;
  final String firstName;
  final String lastName;
  final String? userProfileImageUrl;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  final UserProfile? userProfile;

  CampsiteReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.firstName,
    required this.lastName,
    this.userProfileImageUrl,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    this.userProfile,
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

    // Xử lý tên người dùng
    String firstName = '';
    String lastName = '';
    String userName = user['name'] ?? '';

    // Nếu có first_name và last_name từ API
    if (user['first_name'] != null && user['last_name'] != null) {
      firstName = user['first_name'];
      lastName = user['last_name'];
    } 
    // Nếu chỉ có name, tách thành firstName và lastName
    else if (userName.isNotEmpty) {
      final nameParts = userName.split(' ');
      if (nameParts.length > 1) {
        firstName = nameParts.first;
        lastName = nameParts.sublist(1).join(' ');
      } else {
        firstName = userName;
        lastName = '';
      }
    }

    // Tạo UserProfile từ thông tin user
    UserProfile? userProfile;
    if (user.isNotEmpty) {
      userProfile = UserProfile(
        id: user['id'] ?? '',
        firstName: firstName,  // Sử dụng firstName đã xử lý
        lastName: lastName,    // Sử dụng lastName đã xử lý
        email: user['email'] ?? '',
        phoneNumber: user['phone_number'] ?? '',
        profileImage: user['profileImage'],
        isProfileCompleted: user['isProfileCompleted'] ?? false,
        gender: user['gender'] ?? 'male',
        isCampsiteOwner: user['isCampsiteOwner'] ?? false,
        campsiteOwnerRequest: user['campsiteOwnerRequest'],
      );
    }

    return CampsiteReview(
      id: json['id'] ?? '',
      userId: user['id'] ?? '',
      userName: userName,
      firstName: firstName,
      lastName: lastName,
      userProfileImageUrl: imageUrl,
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      userProfile: userProfile,
    );
  }

  String get fullName {
    // Ưu tiên sử dụng thông tin từ UserProfile nếu có
    if (userProfile != null) {
      return userProfile!.fullName;
    }
    
    // Nếu có cả firstName và lastName
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    
    // Nếu chỉ có firstName
    if (firstName.isNotEmpty) {
      return firstName;
    }
    
    // Fallback về userName nếu không có thông tin khác
    return userName;
  }
} 