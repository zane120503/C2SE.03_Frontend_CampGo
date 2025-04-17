import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:CampGo/model/user_model.dart';
import 'package:CampGo/model/address_model.dart';
import 'package:CampGo/model/card_model.dart';
import 'package:CampGo/model/categories_model.dart';
import 'package:CampGo/config/config.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/api/api.service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DataService {
  final String baseUrl = Config.baseUrl;
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';

  // API thật
  Future<UserProfile?> getUserProfile() async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return _loadLocalUserProfile();
      }

      // Lấy token
      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
        return _loadLocalUserProfile();
      }

      // Gọi API với token
      final response = await APIService.getUserProfile();
      print('API Response: $response');

      if (response['success'] == true && response['userData'] != null) {
        final userData = response['userData'];
        return UserProfile(
          userName: userData['user_name'] ?? userData['name'] ?? '',
          email: userData['email'] ?? '',
          profileImage: userData['profileImage'] ?? '',
          phone: userData['phone_number'] ?? '',
          address: userData['address'] ?? '',
        );
      } else {
        print('Invalid API response format');
        return _loadLocalUserProfile();
      }
    } catch (e) {
      print('Error getting user profile from API: $e');
      return _loadLocalUserProfile();
    }
  }

  // Load local profile as fallback
  Future<UserProfile?> _loadLocalUserProfile() async {
    try {
      print('Loading local user profile...');
      final String jsonData = await rootBundle.loadString('assets/data/user_profile.json');
      final data = json.decode(jsonData);
      return UserProfile.fromJson(data);
    } catch (e) {
      print('Error loading local user profile: $e');
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

      String? token = await AuthService.getToken();
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
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return [];
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
        return [];
      }

      print('Loading addresses with token: ${token.substring(0, 10)}...');

      final response = await APIService.getAddresses();
      print('Addresses API response: $response');

      if (response['success'] == true) {
        if (response['data'] == null || (response['data'] as List).isEmpty) {
          print('No addresses found for user');
          return [];
        }
        
        final addresses = (response['data'] as List).map((json) {
          print('Processing address: $json');
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

        print('Successfully loaded ${addresses.length} addresses');
        return addresses;
      } else {
        print('API returned success: false');
        return [];
      }
    } catch (e) {
      print('Error loading addresses from API: $e');
      return [];
    }
  }

  Future<List<CardModel>> loadCards() async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return [];
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/AllCards'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => CardModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading cards: $e');
      return [];
    }
  }

  Future<bool> deleteCard(String cardId) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return false;
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/DeleteCards/$cardId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting card: $e');
      return false;
    }
  }

  Future<bool> setDefaultCard(String cardId) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return false;
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/cards/$cardId/set-default'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error setting default card: $e');
      return false;
    }
  }

  Future<bool> updateCard(String cardId, Map<String, dynamic> cardData) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return false;
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
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

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating card: $e');
      return false;
    }
  }

  Future<bool> addCard(Map<String, dynamic> cardData) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return false;
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
        return false;
      }

      print('Adding card with data: ${json.encode(cardData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/AddCards'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(cardData),
      );

      print('Add card response status: ${response.statusCode}');
      print('Add card response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Card added successfully');
          return true;
        } else {
          print('Card add failed: ${data['message']}');
          return false;
        }
      }
      print('Card add failed with status: ${response.statusCode}');
      return false;
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
  Future<List<Categories>> loadCategories() async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return _loadLocalCategories();
      }

      // Lấy token
      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
        return _loadLocalCategories();
      }

      print('Loading categories with token: ${token.substring(0, 10)}...');

      // Gọi API danh mục
      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Categories API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Categories API response: ${data.toString().substring(0, 100)}...');
        
        if (data['success'] == true && data['data'] != null) {
          final categories = (data['data'] as List)
              .map((json) => Categories(
                    id: json['_id'] ?? '',
                    name: json['categoryName'] ?? '',
                    description: json['description'] ?? '',
                    imageURL: json['imageURL'],
                  ))
              .toList();
          
          print('Found ${categories.length} categories from API');
          
          // Thêm danh mục "Tất cả" vào đầu danh sách
          categories.insert(0, Categories(
            id: "all",
            name: "Tất cả",
            description: "Tất cả sản phẩm",
            imageURL: null,
          ));
          
          return categories;
        }
      }
      
      print('Failed to get categories from API, using local data');
      return _loadLocalCategories();
    } catch (e) {
      print('Error loading categories from API: $e');
      return _loadLocalCategories();
    }
  }

  // Load local categories as fallback
  Future<List<Categories>> _loadLocalCategories() async {
    try {
      final String jsonData = await rootBundle.loadString('assets/data/Categories.json');
      final data = json.decode(jsonData);
      return (data['categories'] as List)
          .map((json) => Categories(
                id: json['id'] ?? '',
                name: json['name'] ?? '',
                description: json['description'] ?? '',
                imageURL: json['imageURL'],
              ))
          .toList();
    } catch (e) {
      print('Error loading local categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> filterProducts({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return {'success': false, 'message': 'User not logged in'};
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        print('No token found');
        return {'success': false, 'message': 'No token found'};
      }

      // Xây dựng query parameters
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

      // Tạo URL với query parameters
      final uri = Uri.parse('$baseUrl/api/products/search').replace(queryParameters: queryParams);
      
      print('Filtering products with URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Filter API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Filter API response: ${data.toString().substring(0, 100)}...');
        
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Products filtered successfully'
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Failed to filter products'
      };
    } catch (e) {
      print('Error filtering products: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  Future<void> saveToken(String token) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString(tokenKey, token);
      APIService.setAuthToken(token); // Set token cho APIService
      print('Token saved: $token'); // Debug log
    });
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    print('Retrieved token: $token'); // Debug log
    if (token != null) {
      APIService.setAuthToken(token); // Set token cho APIService khi lấy ra
    }
    return token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    APIService.setAuthToken(''); // Xóa token trong APIService
    print('Token cleared'); // Debug log
  }

  static Future<AddressUser?> getDefaultAddress() async {
    try {
      final response = await APIService.getAddresses();
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