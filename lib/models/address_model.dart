class AddressUser {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String street;
  final String district;
  final String city;
  final String ward;
  final String country;
  final String zipCode;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  AddressUser({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.street,
    required this.district,
    required this.city,
    required this.ward,
    required this.country,
    required this.zipCode,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory AddressUser.fromJson(Map<String, dynamic> json) {
    return AddressUser(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      street: json['street'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      ward: json['ward'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'street': street,
      'district': district,
      'city': city,
      'ward': ward,
      'country': country,
      'zipCode': zipCode,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
} 