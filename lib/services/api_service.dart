import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:CampGo/config/config.dart';
import 'package:CampGo/services/auth_service.dart';

class APIService {
  static final String baseUrl = Config.baseUrl;

  // Phương thức tìm kiếm sản phẩm
  static Future<Map<String, dynamic>> searchProducts({
    String query = '',
    String? categoryId,
    int? minPrice,
    int? maxPrice,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Lấy token
      String? token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      // Xây dựng URL với các tham số
      final queryParams = <String, String>{
        'query': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (categoryId != null && categoryId != 'all') {
        queryParams['categoryId'] = categoryId;
      }

      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }

      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }

      final uri = Uri.parse('$baseUrl/api/products/search').replace(queryParameters: queryParams);
      print('Generated URL with param: $uri');

      // Gọi API
      print('Đang kết nối đến API: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Phản hồi từ API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Error: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('Error in searchProducts: $e');
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Phương thức lấy chi tiết sản phẩm
  static Future<Map<String, dynamic>> getProductDetails(String productId) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Lấy token
      String? token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final uri = Uri.parse('$baseUrl/api/products/$productId');
      print('Generated URL with param: $uri');

      // Gọi API
      print('Đang kết nối đến API: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Phản hồi từ API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Error: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('Error in getProductDetails: $e');
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Phương thức lấy đánh giá sản phẩm
  static Future<Map<String, dynamic>> getProductReviews(String productId) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Lấy token
      String? token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final uri = Uri.parse('$baseUrl/api/products/$productId/reviews');
      print('Generated URL with param: $uri');

      // Gọi API
      print('Đang kết nối đến API: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Phản hồi từ API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Error: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('Error in getProductReviews: $e');
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Phương thức cập nhật profile người dùng
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String gender,
    File? profileImage,
    bool? isProfileCompleted,
  }) async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not logged in'};
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      // Chuẩn bị dữ liệu cơ bản
      final Map<String, dynamic> data = {
        'user_name': name,
        'email': email,
        'phone_number': phone,
        'gender': gender,
        'isProfileCompleted': isProfileCompleted ?? false,
        'isAccountVerified': true,
        'verifyOtp': '',
        'verifyOtpExpireAt': 0,
        'resetOtp': '',
        'resetOtpExpireAt': '0'
      };

      // Nếu không có ảnh, sử dụng PUT request thông thường
      if (profileImage == null) {
        final response = await http.put(
          Uri.parse('$baseUrl/api/update-profile'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(data),
        );

        print('Update profile API response status: ${response.statusCode}');
        print('Update profile API response body: ${response.body}');

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
        
        final responseData = json.decode(response.body);
        return responseData;
      }

      // Nếu có ảnh, sử dụng multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/update-profile'),
      );

      // Thêm headers
      request.headers['Authorization'] = 'Bearer $token';

      // Thêm các trường thông tin
      request.fields.addAll({
        'user_name': name,
        'email': email,
        'phone_number': phone,
        'gender': gender,
        'isProfileCompleted': (isProfileCompleted ?? false).toString(),
        'isAccountVerified': 'true',
        'verifyOtp': '',
        'verifyOtpExpireAt': '0',
        'resetOtp': '',
        'resetOtpExpireAt': '0'
      });

      // Thêm file ảnh
      if (profileImage != null) {
        final mimeType = lookupMimeType(profileImage.path);
        request.files.add(await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ));
      }

      // Gửi request và nhận response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Update profile API response status: ${response.statusCode}');
      print('Update profile API response body: ${response.body}');

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      print('Error in updateProfile: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Phương thức lấy thông tin profile người dùng
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      // Kiểm tra đăng nhập và token
      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not logged in'};
      }

      String? token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/data-users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Get profile API response status: ${response.statusCode}');
      print('Get profile API response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      print('Error in getUserProfile: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
} 