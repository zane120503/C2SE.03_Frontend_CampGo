import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:CampGo/config/config.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/services/share_service.dart';
import 'package:dio/dio.dart';

class APIService {
  static final String baseUrl = Config.baseUrl;
  final AuthService _authService = AuthService();
  final Dio _dio = Dio();
  
  static Future<String?> _getAuthToken() async {
    try {
      final token = await ShareService.getToken();
      print('Getting token from ShareService: $token');
      if (token == null || token.isEmpty) {
        print('Token is null or empty');
        return null;
      }
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    String? token = await ShareService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

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
      String? token = await ShareService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      // Xây dựng URL với các tham số
      final queryParams = <String, String>{
        'search': query,
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
      print('Search URL: $uri');

      // Gọi API
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Search response status: ${response.statusCode}');
      print('Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Chuyển đổi dữ liệu để phù hợp với frontend
          final List<dynamic> products = data['data']['products'] ?? [];
          return {
            'success': true,
            'data': {
              'products': products.map((product) => {
                '_id': product['_id'],
                'productName': product['productName'],
                'price': product['price']?.toDouble() ?? 0.0,
                'imageURL': product['imageURL'],
                'rating': product['rating']?.toDouble() ?? 0.0,
                'discount': product['discount']?.toDouble() ?? 0.0,
                'stockQuantity': product['stockQuantity'] ?? 0,
                'sold': product['sold'] ?? 0,
              }).toList(),
            },
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Không tìm thấy sản phẩm phù hợp',
        'data': {'products': []}
      };
    } catch (e) {
      print('Error in searchProducts: $e');
      return {
        'success': false,
        'message': 'Lỗi khi tìm kiếm: $e',
        'data': {'products': []}
      };
    }
  }

  // Phương thức lấy chi tiết sản phẩm
  static Future<Map<String, dynamic>> getProductDetails(String productId) async {
    try {
      final token = await ShareService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Product details response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể lấy thông tin sản phẩm',
        };
      }
    } catch (e) {
      print('Error getting product details: $e');
      return {
        'success': false,
        'message': 'Lỗi khi lấy thông tin sản phẩm: $e',
      };
    }
  }

  // Phương thức lấy đánh giá sản phẩm
  static Future<Map<String, dynamic>> getProductReviews(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productId/reviews'),
        headers: await _getHeaders(),
      );

      print('Reviews API Response status: ${response.statusCode}');
      print('Reviews API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': {
            'reviews': data['data']['reviews'] ?? [],
            'summary': {
              'averageRating': data['data']['summary']['averageRating'] ?? 0.0,
              'totalReviews': data['data']['summary']['totalReviews'] ?? 0,
            }
          }
        };
      } else {
        print('Failed to load reviews. Status code: ${response.statusCode}');
        return {
          'success': false,
          'data': {
            'reviews': [],
            'summary': {
              'averageRating': 0.0,
              'totalReviews': 0,
            }
          }
        };
      }
    } catch (e) {
      print('Error loading reviews: $e');
      return {
        'success': false,
        'data': {
          'reviews': [],
          'summary': {
            'averageRating': 0.0,
            'totalReviews': 0,
          }
        }
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
    bool isProfileCompleted = true,
  }) async {
    try {
      // Lấy token từ ShareService
      String? token = await ShareService.getToken();
      print('Token for update profile: $token');
      
      if (token == null || token.isEmpty) {
        print('No token found for update profile');
        return {
          'success': false,
          'message': 'Không có token xác thực. Vui lòng đăng nhập lại.'
        };
      }

      // Tách tên thành first_name và last_name
      final nameParts = name.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Chuẩn bị dữ liệu
      var dio = Dio();
      
      // Cấu hình Dio instance
      dio.options.baseUrl = baseUrl;
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      // Tạo form data
      var formData = FormData.fromMap({
        'first_name': firstName,
        'last_name': lastName,
        'user_name': name,
        'email': email,
        'phone_number': phone,
        'gender': gender,
        'isProfileCompleted': isProfileCompleted.toString()
      });

      // Thêm file ảnh nếu có
      if (profileImage != null) {
        String fileName = profileImage.path.split('/').last;
        formData.files.add(
          MapEntry(
            'profileImage',
            await MultipartFile.fromFile(
              profileImage.path,
              filename: fileName,
              contentType: MediaType.parse(lookupMimeType(profileImage.path) ?? 'image/jpeg'),
            ),
          ),
        );
      }

      print('Sending update profile request...');
      print('URL: $baseUrl/api/update-profile');
      print('Headers: ${dio.options.headers}');
      print('FormData fields: ${formData.fields}');

      // Gửi request
      final response = await dio.put('/api/update-profile', data: formData);

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = response.data;
        
        if (data['success'] == true) {
          // Lưu thông tin user mới vào ShareService
          await ShareService.saveUserInfo(
            userId: data['data']['_id'] ?? '',
            email: data['data']['email'] ?? email,
            userName: data['data']['user_name'] ?? name,
            isProfileCompleted: true
          );

          return {
            'success': true,
            'data': data['data'],
            'message': 'Cập nhật thông tin thành công'
          };
        }
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Cập nhật thông tin thất bại'
      };

    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      print('Dio error response: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Lỗi kết nối: ${e.message}'
      };
    } catch (e) {
      print('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Lỗi cập nhật thông tin: ${e.toString()}'
      };
    }
  }

  // Phương thức lấy thông tin profile người dùng
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getAuthToken();
      print('Token for get user profile: $token');
      
      if (token == null || token.isEmpty) {
        print('No token found for get user profile');
        return {
          'success': false,
          'message': 'Không có token xác thực. Vui lòng đăng nhập lại.'
        };
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

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      print('Error in getUserProfile: $e');
      return {
        'success': false,
        'message': 'Lỗi lấy thông tin người dùng: ${e.toString()}'
      };
    }
  }

  // Address APIs
  Future<Map<String, dynamic>> getAddresses() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await _dio.get(
        '${Config.baseUrl}/api/AllAddresses',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } catch (e) {
      print('Error getting addresses: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await _dio.post(
        '${Config.baseUrl}/api/addresses',
        data: addressData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } catch (e) {
      print('Error adding address: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }

      final response = await _dio.put(
        '${Config.baseUrl}/api/addresses/$addressId',
        data: addressData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data['success'] == true;
    } catch (e) {
      print('Error updating address: $e');
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }

      final response = await _dio.delete(
        '${Config.baseUrl}/api/addresses/$addressId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data['success'] == true;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }

      final response = await _dio.put(
        '${Config.baseUrl}/api/addresses/$addressId/set-default',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data['success'] == true;
    } catch (e) {
      print('Error setting default address: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> addCard(Map<String, dynamic> cardData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await _dio.post(
        '${Config.baseUrl}/api/AddCards',
        data: cardData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } catch (e) {
      print('Error adding card: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAllCards() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await _dio.get(
        '${Config.baseUrl}/api/AllCards',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } catch (e) {
      print('Error getting cards: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> updateCard(String cardId, Map<String, dynamic> cardData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }

      final response = await _dio.put(
        '${Config.baseUrl}/api/UpdateCards/$cardId',
        data: cardData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data['success'] == true;
    } catch (e) {
      print('Error updating card: $e');
      return false;
    }
  }

  Future<bool> deleteCard(String cardId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }

      final response = await _dio.delete(
        '${Config.baseUrl}/api/DeleteCards/$cardId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data['success'] == true;
    } catch (e) {
      print('Error deleting card: $e');
      return false;
    }
  }

  Future<bool> setDefaultCard(String cardId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }

      final response = await _dio.put(
        '${Config.baseUrl}/api/cards/$cardId/set-default',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data['success'] == true;
    } catch (e) {
      print('Error setting default card: $e');
      return false;
    }
  }

  // Phương thức lấy tất cả danh mục
  static Future<Map<String, dynamic>> getAllCategories() async {
    try {
      final token = await _getAuthToken();
      print('Token for get categories: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Get categories API response status: ${response.statusCode}');
      print('Get categories API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'message': responseData['message'] ?? 'Lấy danh mục thành công'
        };
      }

      return {
        'success': false,
        'message': 'Lỗi khi lấy danh mục sản phẩm'
      };
    } catch (e) {
      print('Error in getAllCategories: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}'
      };
    }
  }

  // Phương thức lấy tất cả sản phẩm
  static Future<Map<String, dynamic>> getAllProducts({
    String? categoryId,
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final token = await ShareService.getToken();
      
      // Xây dựng URL endpoint
      String endpoint;
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        endpoint = '/api/categories/$categoryId/products';
      } else {
        endpoint = '/api/products';
      }
      
      // Xây dựng query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      };

      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
      
      print('Calling API URL: $uri');
      print('Query Parameters: $queryParams');
      print('Price Range: $minPrice - $maxPrice');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> rawProducts = responseData['data']['products'] ?? [];
          
          // Lọc và chuyển đổi sản phẩm
          final List<Map<String, dynamic>> transformedProducts = rawProducts.where((product) {
            // Tính giá sau giảm giá
            final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
            final discount = (product['discount'] ?? 0).toDouble();
            final finalPrice = price * (1 - discount / 100);
            
            // Kiểm tra khoảng giá
            bool isInPriceRange = true;
            if (minPrice != null) {
              isInPriceRange = isInPriceRange && finalPrice >= minPrice;
            }
            if (maxPrice != null) {
              isInPriceRange = isInPriceRange && finalPrice <= maxPrice;
            }
            
            return isInPriceRange;
          }).map((product) {
            // Xử lý hình ảnh từ backend
            String imageUrl = '';
            if (product['images'] != null && product['images'] is List && product['images'].isNotEmpty) {
              var firstImage = product['images'][0];
              if (firstImage is Map && firstImage.containsKey('url')) {
                imageUrl = firstImage['url'].toString();
              } else if (firstImage is String) {
                imageUrl = firstImage;
              }
            } else if (product['imageURL'] != null) {
              imageUrl = product['imageURL'];
            }

            // Thêm base URL nếu imageUrl là đường dẫn tương đối
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = '${Config.baseUrl}$imageUrl';
            }

            print('Product ID: ${product['_id']}');
            print('Product Name: ${product['productName']}');
            print('Original Price: ${product['price']}');
            print('Discount: ${product['discount']}%');
            print('Discounted Price: ${product['price'] * (1 - product['discount'] / 100)}');
            print('Image URL: $imageUrl');
            
            return {
              '_id': product['_id'] ?? '',
              'name': product['productName'] ?? '',
              'description': product['description'] ?? '',
              'originalPrice': product['price'] ?? 0.0,
              'price': product['price'] ?? 0.0,
              'discountedPrice': product['price'] * (1 - product['discount'] / 100),
              'imageURL': imageUrl,
              'rating': product['rating']?.toDouble() ?? 5.0,
              'soldCount': product['sold'] ?? 0,
              'stockQuantity': product['stockQuantity'] ?? 0,
              'categoryID': product['categoryID'] ?? '',
              'brand': product['brand'] ?? '',
              'discount': product['discount']?.toDouble() ?? 0.0,
            };
          }).toList();

          print('Found ${transformedProducts.length} products in price range');

          return {
            'success': true,
            'data': {
              'products': transformedProducts,
            },
            'message': 'Lấy sản phẩm thành công'
          };
        }
      }

      return {
        'success': false,
        'message': 'Không thể lấy danh sách sản phẩm',
        'data': {'products': []}
      };

    } catch (e) {
      print('Error in getAllProducts: $e');
      return {
        'success': false,
        'message': 'Có lỗi xảy ra khi tải sản phẩm: $e',
        'data': {'products': []}
      };
    }
  }

  static Future<Map<String, dynamic>> getProductsByCategory({
    required String categoryId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await ShareService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/api/categories/$categoryId/products?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get products by category response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting products by category: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getCart() async {
    try {
      final token = await ShareService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để xem giỏ hàng',
          'data': {'items': [], 'cartTotal': 0.0}
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get cart response status: ${response.statusCode}');
      print('Get cart response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final items = data['data']['items'] as List<dynamic>? ?? [];
          final cartTotal = (data['data']['cartTotal'] ?? 0.0).toDouble();
          
          // Kiểm tra và xử lý các sản phẩm null
          final validItems = items.where((item) => 
            item['product'] != null && 
            item['quantity'] != null && 
            item['price'] != null
          ).toList();
          
          return {
            'success': true,
            'data': {
              'items': validItems,
              'cartTotal': cartTotal
            },
            'message': 'Lấy giỏ hàng thành công'
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Không thể lấy thông tin giỏ hàng',
        'data': {'items': [], 'cartTotal': 0.0}
      };
    } catch (e) {
      print('Error getting cart: $e');
      return {
        'success': false,
        'message': 'Lỗi khi lấy thông tin giỏ hàng: $e',
        'data': {'items': [], 'cartTotal': 0.0}
      };
    }
  }

  static Future<Map<String, dynamic>> addToCart(String productId, int quantity) async {
    try {
      final token = await ShareService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để thêm vào giỏ hàng'
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': productId,
          'quantity': quantity,
        }),
      );

      print('Add to cart response status: ${response.statusCode}');
      print('Add to cart response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': 'Thêm vào giỏ hàng thành công',
            'data': data['data']
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Không thể thêm vào giỏ hàng'
      };
    } catch (e) {
      print('Error adding to cart: $e');
      return {
        'success': false,
        'message': 'Lỗi khi thêm vào giỏ hàng: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> updateCartItem(String productId, int quantity) async {
    try {
      final token = await ShareService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để cập nhật giỏ hàng'
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/cart/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': productId,
          'quantity': quantity,
        }),
      );

      print('Update cart item response: ${response.body}');
      
      final data = json.decode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Cập nhật giỏ hàng thành công',
        'data': data['data']
      };
    } catch (e) {
      print('Error updating cart item: $e');
      return {
        'success': false,
        'message': 'Lỗi khi cập nhật giỏ hàng: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(String productId) async {
    try {
      final token = await ShareService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để xóa sản phẩm khỏi giỏ hàng'
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Remove from cart response: ${response.statusCode} - ${response.body}');
      
      final data = json.decode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Xóa sản phẩm khỏi giỏ hàng thành công',
        'data': data['data']
      };
    } catch (e) {
      print('Error removing item from cart: $e');
      return {
        'success': false,
        'message': 'Lỗi khi xóa sản phẩm khỏi giỏ hàng: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> clearCart() async {
    try {
      final token = await ShareService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để xóa giỏ hàng'
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Clear cart response: ${response.statusCode} - ${response.body}');
      
      final data = json.decode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Xóa giỏ hàng thành công',
        'data': data['data']
      };
    } catch (e) {
      print('Error clearing cart: $e');
      return {
        'success': false,
        'message': 'Lỗi khi xóa giỏ hàng: $e'
      };
    }
  }

  // Phương thức lấy danh sách yêu thích
  static Future<Map<String, dynamic>> getWishlist() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập để xem danh sách yêu thích');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/wishlist'),
        headers: await _getHeaders(),
      );

      print('Get wishlist response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final products = responseData['data']['products'] as List<dynamic>;
          
          return {
            'success': true,
            'data': products.map((product) => {
              '_id': product['_id'],
              'productName': product['productName'],
              'price': product['price'],
              'imageURL': product['imageURL'],
              'stockQuantity': product['stockQuantity'],
              'discount': product['discount'],
              'original_price': product['original_price'],
              'discount_price': product['discount_price'],
              'description': product['description'],
              'brand': product['brand'],
              'sold': product['sold'],
            }).toList(),
            'message': 'Lấy danh sách yêu thích thành công'
          };
        }
      }
      
      throw Exception('Lỗi khi lấy danh sách yêu thích: ${response.body}');
    } catch (e) {
      print('Error getting wishlist: $e');
      return {
        'success': false,
        'data': [],
        'message': 'Lỗi khi lấy danh sách yêu thích: $e'
      };
    }
  }

  // Phương thức thêm vào danh sách yêu thích
  static Future<Map<String, dynamic>> addToWishlist(String productId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để thêm vào danh sách yêu thích'
        };
      }

      if (productId.isEmpty) {
        return {
          'success': false,
          'message': 'Product ID không được để trống'
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/wishlist/add'),
        headers: await _getHeaders(),
        body: json.encode({'productId': productId}),
      );

      print('Add to wishlist response: ${response.statusCode} - ${response.body}');
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Đã thêm vào danh sách yêu thích'
        };
      } else if (response.statusCode == 400 && responseData['message']?.contains('already in wishlist') == true) {
        return {
          'success': false,
          'message': 'Sản phẩm đã có trong danh sách yêu thích'
        };
      }
      
      return {
        'success': false,
        'message': responseData['message'] ?? 'Không thể thêm vào danh sách yêu thích'
      };
    } catch (e) {
      print('Error adding to wishlist: $e');
      return {
        'success': false,
        'message': 'Lỗi khi thêm vào danh sách yêu thích'
      };
    }
  }

  // Phương thức xóa khỏi danh sách yêu thích
  static Future<Map<String, dynamic>> removeFromWishlist(String productId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để xóa khỏi danh sách yêu thích'
        };
      }

      if (productId.isEmpty) {
        return {
          'success': false,
          'message': 'Product ID không được để trống'
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/wishlist/$productId'),
        headers: await _getHeaders(),
      );

      print('Remove from wishlist response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? 'Đã xóa khỏi danh sách yêu thích'
        };
      }
      
      return {
        'success': false,
        'message': 'Không thể xóa khỏi danh sách yêu thích: ${response.body}'
      };
    } catch (e) {
      print('Error removing from wishlist: $e');
      return {
        'success': false,
        'message': 'Lỗi khi xóa khỏi danh sách yêu thích'
      };
    }
  }

  static Future<Map<String, dynamic>> createProductReview(
    String productId,
    double rating,
    String comment,
    List<String> images,
  ) async {
    try {
      final token = await ShareService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để đánh giá sản phẩm'
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/products/$productId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rating': rating,
          'comment': comment,
          'images': images,
        }),
      );

      print('Create review response: ${response.body}');
      
      final data = json.decode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Đánh giá sản phẩm thành công',
        'data': data['data']
      };
    } catch (e) {
      print('Error creating review: $e');
      return {
        'success': false,
        'message': 'Lỗi khi đánh giá sản phẩm: $e'
      };
    }
  }
} 