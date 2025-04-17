import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlacesService {
  static const String _apiKey = 'YOUR_API_KEY_HERE'; // Thay YOUR_API_KEY_HERE bằng API key thật của bạn
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Tìm kiếm địa điểm
  Future<List<Place>> searchPlaces(String query, LatLng? location) async {
    try {
      final radius = 50000; // Bán kính tìm kiếm (mét)
      final defaultLocation = const LatLng(16.0544, 108.2022); // Mặc định ở Đà Nẵng
      final searchLocation = location ?? defaultLocation;
      
      final url = Uri.parse(
        '$_baseUrl/textsearch/json?query=$query'
        '&location=${searchLocation.latitude},${searchLocation.longitude}'
        '&radius=$radius'
        '&key=$_apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['results'] as List)
              .map((place) => Place.fromJson(place))
              .toList();
        }
      }
      throw Exception('Không tìm thấy kết quả');
    } catch (e) {
      throw Exception('Lỗi tìm kiếm: $e');
    }
  }

  // Lấy chi tiết địa điểm
  Future<PlaceDetail> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceDetail.fromJson(data['result'], _apiKey);
        }
      }
      throw Exception('Không tìm thấy thông tin địa điểm');
    } catch (e) {
      throw Exception('Lỗi lấy chi tiết: $e');
    }
  }
}

class Place {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double rating;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.rating,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return Place(
      id: json['place_id'],
      name: json['name'],
      address: json['formatted_address'],
      location: LatLng(
        location['lat'],
        location['lng'],
      ),
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}

class PlaceDetail {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double rating;
  final String? phoneNumber;
  final String? website;
  final List<String> photos;
  final Map<String, dynamic> openingHours;

  PlaceDetail({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.rating,
    this.phoneNumber,
    this.website,
    required this.photos,
    required this.openingHours,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json, String apiKey) {
    final location = json['geometry']['location'];
    return PlaceDetail(
      id: json['place_id'],
      name: json['name'],
      address: json['formatted_address'],
      location: LatLng(
        location['lat'],
        location['lng'],
      ),
      rating: (json['rating'] ?? 0.0).toDouble(),
      phoneNumber: json['formatted_phone_number'],
      website: json['website'],
      photos: json['photos'] != null
          ? (json['photos'] as List)
              .map((photo) => 
                'https://maps.googleapis.com/maps/api/place/photo'
                '?maxwidth=400'
                '&photo_reference=${photo['photo_reference']}'
                '&key=$apiKey')
              .toList()
          : [],
      openingHours: json['opening_hours'] ?? {},
    );
  }
} 