import 'package:latlong2/latlong.dart';

class Campsite {
  final String id;
  final String name;
  final String location;
  final LatLng coordinates;
  final String description;
  final List<CampsiteImage> images;
  final List<String> facilities;
  final double rating;
  final List<String> reviews;
  final PriceRange priceRange;
  final ContactInfo contactInfo;
  final OpeningHours openingHours;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Campsite({
    required this.id,
    required this.name,
    required this.location,
    required this.coordinates,
    required this.description,
    required this.images,
    required this.facilities,
    required this.rating,
    required this.reviews,
    required this.priceRange,
    required this.contactInfo,
    required this.openingHours,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Campsite.fromJson(Map<String, dynamic> json) {
    return Campsite(
      id: json['_id'] ?? '',
      name: json['campsiteName'] ?? '',
      location: json['location'] ?? '',
      coordinates: LatLng(
        json['latitude']?.toDouble() ?? 0.0,
        json['longitude']?.toDouble() ?? 0.0,
      ),
      description: json['description'] ?? '',
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => CampsiteImage.fromJson(img))
          .toList() ?? [],
      facilities: List<String>.from(json['facilities'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: List<String>.from(json['reviews'] ?? []),
      priceRange: PriceRange.fromJson(json['priceRange'] ?? {}),
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
      openingHours: OpeningHours.fromJson(json['openingHours'] ?? {}),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
}

class CampsiteImage {
  final String url;
  final String publicId;

  CampsiteImage({
    required this.url,
    required this.publicId,
  });

  factory CampsiteImage.fromJson(Map<String, dynamic> json) {
    return CampsiteImage(
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
    );
  }
}

class PriceRange {
  final double min;
  final double max;

  PriceRange({
    required this.min,
    required this.max,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
    );
  }
}

class ContactInfo {
  final String? phone;
  final String? email;
  final String? website;

  ContactInfo({
    this.phone,
    this.email,
    this.website,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
    );
  }
}

class OpeningHours {
  final String? open;
  final String? close;

  OpeningHours({
    this.open,
    this.close,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      open: json['open'],
      close: json['close'],
    );
  }
} 