class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final Map<String, dynamic>? profileImage;
  final bool isProfileCompleted;
  final String gender;
  final bool isCampsiteOwner;
  final Map<String, dynamic>? campsiteOwnerRequest;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
    required this.isProfileCompleted,
    required this.gender,
    this.isCampsiteOwner = false,
    this.campsiteOwnerRequest,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? json['firstName']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? json['phoneNumber']?.toString() ?? '',
      profileImage: json['profileImage'] is Map ? json['profileImage'] : null,
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      gender: json['gender']?.toString() ?? 'male',
      isCampsiteOwner: json['isCampsiteOwner'] ?? false,
      campsiteOwnerRequest: json['campsiteOwnerRequest'] is Map ? json['campsiteOwnerRequest'] : null,
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
      'isCampsiteOwner': isCampsiteOwner,
      'campsiteOwnerRequest': campsiteOwnerRequest,
    };
  }

  String get fullName => '$firstName $lastName';
} 