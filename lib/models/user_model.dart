class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final Map<String, dynamic>? profileImage;
  final bool isProfileCompleted;
  final String gender;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
    required this.isProfileCompleted,
    required this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      profileImage: json['profileImage'] is Map ? json['profileImage'] : null,
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      gender: json['gender']?.toString() ?? 'male',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'profileImage': profileImage,
      'isProfileCompleted': isProfileCompleted,
      'gender': gender,
    };
  }

  String get fullName => '$firstName $lastName';
} 