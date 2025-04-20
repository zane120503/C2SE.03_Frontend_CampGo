class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final String? profileImage;
  final bool isProfileCompleted;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.profileImage,
    required this.isProfileCompleted,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone_number'],
      address: json['address'],
      profileImage: json['profileImage'],
      isProfileCompleted: json['isProfileCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phone,
      'address': address,
      'profileImage': profileImage,
      'isProfileCompleted': isProfileCompleted,
    };
  }

  String get fullName => '$firstName $lastName';
} 