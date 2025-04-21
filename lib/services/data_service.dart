import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:CampGo/models/user_model.dart';
import 'package:CampGo/models/address_model.dart';
import 'package:CampGo/models/category.dart';
import 'package:CampGo/models/card_model.dart';
import 'package:CampGo/config/config.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/services/share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DataService {
  final String baseUrl = Config.baseUrl;
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  final AuthService _authService = AuthService();
  final APIService _apiService = APIService();

  // API thật
  Future<UserProfile?> getUserProfile() async {
    try {
      final response = await APIService.getUserProfile();
      print('Get user profile response: $response');

      if (response['success'] == true && response['userData'] != null) {
        final userData = response['userData'];
        
        // Lưu thông tin user vào local storage
        await ShareService.saveUserInfo(
          userId: userData['_id'] ?? '',
          email: userData['email'] ?? '',
          userName: userData['user_name'] ?? '',
          isProfileCompleted: userData['isProfileCompleted'] ?? false,
        );

        return UserProfile(
          id: userData['_id'] ?? '',
          firstName: userData['first_name'] ?? '',
          lastName: userData['last_name'] ?? '',
          email: userData['email'] ?? '',
          phone: userData['phone_number'] ?? '',
          address: userData['address'] ?? '',
          profileImage: userData['profileImage'],
          isProfileCompleted: userData['isProfileCompleted'] ?? false,
        );
      }

      print('Failed to get user profile: ${response['message']}');
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return false;
      }

      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Đọc dữ liệu từ JSON local
  Future<List<AddressUser>> loadAddresses() async {
    try {
      final response = await _apiService.getAddresses();
      print('Load addresses response: $response');

      if (response['success'] == true && response['data'] != null) {
        final addressList = (response['data'] as List).map((json) {
          return AddressUser(
            id: json['_id'] ?? '',
            userId: json['user_id'] ?? '',
            fullName: json['fullName'] ?? '',
            phoneNumber: json['phoneNumber'] ?? '',
            street: json['street'] ?? '',
            city: json['city'] ?? '',
            district: json['district'] ?? '',
            ward: json['ward'] ?? '',
            country: json['country'] ?? '',
            zipCode: json['zipCode'] ?? '',
            isDefault: json['isDefault'] ?? false,
            createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
            updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
            v: json['__v'] ?? 0,
          );
        }).toList();

        return addressList;
      }

      print('Failed to load addresses: ${response['message']}');
      return [];
    } catch (e) {
      print('Error loading addresses: $e');
      return [];
    }
  }

  Future<List<CardModel>> loadCards() async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for loading cards');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/AllCards'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Load cards API response status: ${response.statusCode}');
      print('Load cards API response body: ${response.body}');

      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => CardModel.fromJson(json))
            .toList();
      }

      print('Failed to load cards: ${data['message']}');
      return [];
    } catch (e) {
      print('Error loading cards: $e');
      return [];
    }
  }

  Future<bool> deleteCard(String cardId) async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for deleting card');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/DeleteCards/$cardId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Delete card API response status: ${response.statusCode}');
      print('Delete card API response body: ${response.body}');

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error deleting card: $e');
      return false;
    }
  }

  Future<bool> setDefaultCard(String cardId) async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for setting default card');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/cards/$cardId/set-default'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Set default card API response status: ${response.statusCode}');
      print('Set default card API response body: ${response.body}');

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error setting default card: $e');
      return false;
    }
  }

  Future<bool> updateCard(String cardId, Map<String, dynamic> cardData) async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for updating card');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/UpdateCards/$cardId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(cardData),
      );

      print('Update card API response status: ${response.statusCode}');
      print('Update card API response body: ${response.body}');

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error updating card: $e');
      return false;
    }
  }

  Future<bool> addCard(Map<String, dynamic> cardData) async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for adding card');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/AddCards'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(cardData),
      );

      print('Add card API response status: ${response.statusCode}');
      print('Add card API response body: ${response.body}');

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error adding card: $e');
      return false;
    }
  }

  Future<Map<String, bool>> loadNotificationSettings() async {
    try {
      final String response = await rootBundle.loadString('assets/data/notification_settings.json');
      final data = json.decode(response);
      return {
        'inAppNotifications': data['inAppNotifications'],
        'emailNotifications': data['emailNotifications'],
        'smsNotifications': data['smsNotifications'],
      };
    } catch (e) {
      print('Error loading notification settings: $e');
      return {
        'inAppNotifications': false,
        'emailNotifications': false,
        'smsNotifications': false,
      };
    }
  }

  // Thêm phương thức loadCategories
  Future<List<Category>> loadCategories() async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for loading categories');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Load categories API response status: ${response.statusCode}');
      print('Load categories API response body: ${response.body}');

      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final categories = (data['data'] as List)
            .map((json) => Category(
                  id: json['_id'] ?? '',
                  categoryName: json['categoryName'] ?? '',
                  description: json['description'] ?? '',
                  imageURL: json['imageURL'] ?? '',
                ))
            .toList();

        // Thêm danh mục "Tất cả" vào đầu danh sách
        categories.insert(0, Category(
          id: "all",
          categoryName: "Tất cả",
          description: "Tất cả sản phẩm",
          imageURL: "",  // Thay null bằng chuỗi rỗng
        ));

        return categories;
      }

      print('Failed to load categories: ${data['message']}');
      return [];
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> filterProducts({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for filtering products');
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập lại'
        };
      }

      Map<String, String> queryParams = {};
      
      if (categoryId != null && categoryId != "all") {
        queryParams['categoryId'] = categoryId;
      }
      
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }

      final uri = Uri.parse('$baseUrl/api/products/search').replace(queryParameters: queryParams);
      
      print('Filtering products with URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Filter products API response status: ${response.statusCode}');
      print('Filter products API response body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('Error filtering products: $e');
      return {
        'success': false,
        'message': 'Lỗi lọc sản phẩm: ${e.toString()}'
      };
    }
  }

  Future<void> saveToken(String token) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString(tokenKey, token);
      print('Token saved: $token');
    });
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    print('Retrieved token: $token');
    return token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    print('Token cleared');
  }

  Future<AddressUser?> getDefaultAddress() async {
    try {
      final response = await _apiService.getAddresses();
      print('Address API response: $response'); // Debug log
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> addresses = response['data'] is List ? response['data'] : [];
        print('Found ${addresses.length} addresses'); // Debug log
        
        if (addresses.isEmpty) {
          print('No addresses found');
          return null;
        }

        // Tìm địa chỉ mặc định hoặc lấy địa chỉ đầu tiên
        final defaultAddress = addresses.firstWhere(
          (addr) => addr['isDefault'] == true,
          orElse: () => addresses.first,
        );

        print('Selected address: $defaultAddress'); // Debug log

        return AddressUser(
          id: defaultAddress['_id']?.toString() ?? '',
          userId: defaultAddress['user_id']?.toString() ?? '',
          fullName: defaultAddress['fullName']?.toString() ?? '',
          phoneNumber: defaultAddress['phoneNumber']?.toString() ?? '',
          street: defaultAddress['street']?.toString() ?? '',
          district: defaultAddress['district']?.toString() ?? '',
          city: defaultAddress['city']?.toString() ?? '',
          ward: defaultAddress['ward']?.toString() ?? '',
          country: defaultAddress['country']?.toString() ?? '',
          zipCode: defaultAddress['zipCode']?.toString() ?? '',
          isDefault: defaultAddress['isDefault'] == true,
          createdAt: DateTime.parse(defaultAddress['createdAt'] ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.parse(defaultAddress['updatedAt'] ?? DateTime.now().toIso8601String()),
          v: defaultAddress['__v'] is num ? defaultAddress['__v'] : 0,
        );
      }
      print('API returned success: false or no data');
      return null;
    } catch (e) {
      print('Error getting default address: $e');
      return null;
    }
  }
} 