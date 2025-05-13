class CampsiteOwnerModel {
  final String? id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> facilities;
  final double minPrice;
  final double maxPrice;
  final String phone;
  final String email;
  final String website;
  final String openHour;
  final String closeHour;

  CampsiteOwnerModel({
    this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.facilities,
    required this.minPrice,
    required this.maxPrice,
    required this.phone,
    required this.email,
    required this.website,
    required this.openHour,
    required this.closeHour,
  });

  factory CampsiteOwnerModel.fromJson(Map<String, dynamic> json) {
    final contact = json['contactInfo'] ?? {};
    final hours = json['openingHours'] ?? {};
    final price = json['priceRange'] ?? {};
    return CampsiteOwnerModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['campsiteName']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: (json['latitude'] is double)
          ? json['latitude']
          : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: (json['longitude'] is double)
          ? json['longitude']
          : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
      facilities: (json['facilities'] is List)
          ? List<String>.from(json['facilities'].map((e) => e.toString()))
          : [],
      minPrice: (price['min'] is double)
          ? price['min']
          : double.tryParse(price['min']?.toString() ?? '0') ?? 0,
      maxPrice: (price['max'] is double)
          ? price['max']
          : double.tryParse(price['max']?.toString() ?? '0') ?? 0,
      phone: contact['phone']?.toString() ?? '',
      email: contact['email']?.toString() ?? '',
      website: contact['website']?.toString() ?? '',
      openHour: hours['open']?.toString() ?? '',
      closeHour: hours['close']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'facilities': facilities,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'phone': phone,
      'email': email,
      'website': website,
      'openHour': openHour,
      'closeHour': closeHour,
    };
  }
} 