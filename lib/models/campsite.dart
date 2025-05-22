import 'package:latlong2/latlong.dart';
import 'campsite_review.dart';
import 'user_model.dart';

class Campsite {
  final String id;
  final String name;
  final String location;
  final LatLng coordinates;
  final String description;
  final List<CampsiteImage> images;
  final List<String> facilities;
  final double rating;
  final List<CampsiteReview> reviews;
  final PriceRange priceRange;
  final ContactInfo contactInfo;
  final OpeningHours openingHours;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? owner;

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
    this.owner,
  });

  factory Campsite.fromJson(Map<String, dynamic> json) {
    // Parse images
    List<CampsiteImage> images = [];
    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List)
          .map((img) => CampsiteImage.fromJson(img))
          .toList();
    }

    // Parse facilities
    List<String> facilities = [];
    if (json['facilities'] != null && json['facilities'] is List) {
      facilities = List<String>.from(json['facilities']);
    }

    // Parse reviews
    List<CampsiteReview> reviews = [];
    if (json['reviews'] != null && json['reviews'] is List) {
      reviews = (json['reviews'] as List)
          .map((review) => CampsiteReview.fromJson(review))
          .toList();
    }

    // Parse owner information
    UserProfile? owner;
    if (json['owner'] != null && json['owner'] is Map) {
      owner = UserProfile.fromJson(json['owner']);
    }

    return Campsite(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      coordinates: LatLng(
        json['coordinates']?['lat'] ?? 0.0,
        json['coordinates']?['lng'] ?? 0.0,
      ),
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: reviews,
      facilities: facilities,
      images: images,
      priceRange: PriceRange.fromJson(json['priceRange'] ?? {}),
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
      openingHours: OpeningHours.fromJson(json['openingHours'] ?? {}),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      owner: owner,
    );
  }

  String get ownerFullName => owner?.fullName ?? 'Unknown Owner';
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