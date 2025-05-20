import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:CampGo/config/config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:CampGo/services/share_service.dart';

class APIService {
  static String? _authToken;
  static Dio? _dio;
  static String get baseUrl => Config.baseUrl;
  static Map<String, dynamic> _cache = {};
  static const String _tokenKey = 'auth_token';

  static void _initDio() {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
        baseUrl: Config.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) {
          return status! < 500;
        },
      ));

      // Thêm interceptor để tự động xử lý token
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Thêm token vào header nếu có
            if (_authToken != null) {
              options.headers['Authorization'] = 'Bearer $_authToken';
            }
            return handler.next(options);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              // Token hết hạn, thử refresh token
              try {
                final refreshed = await _refreshToken();
                if (refreshed) {
                  // Thử lại request ban đầu với token mới
                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $_authToken';
                  final response = await _dio!.fetch(opts);
                  return handler.resolve(response);
                }
              } catch (e) {
                print('Error refreshing token: $e');
              }
            }
            return handler.next(error);
          },
        ),
      );
    }
  }

  static Future<bool> _refreshToken() async {
    try {
      final response = await _dio!.post('/api/auth/refresh-token');
      if (response.statusCode == 200 && response.data['token'] != null) {
        _authToken = response.data['token'];
        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // Setter cho auth token
  static void setAuthToken(String token) {
    print('Setting auth token: $token'); // Debug log
    _authToken = token;
    _initDio();
  }

  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  // AUTH METHODS
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _initDio(); // Khởi tạo _dio trước khi gọi API
      print('Đang kết nối đến API login...'); // Debug log
      
      final response = await _dio!.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('Login response: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['token'] != null) {
          setAuthToken(data['token']);
        }
        return data;
      }
      throw Exception('Đăng nhập thất bại');
    } catch (e) {
      print('Error during login: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse(Config.getFullUrl(Config.authEndpoints['register']!)),
        headers: Config.defaultHeaders,
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Đăng ký thất bại');
    } catch (e) {
      print('Error during registration: $e');
      throw Exception('Lỗi kết nối');
    }
  }

  // USER PROFILE METHODS
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      _initDio(); // Đảm bảo _dio đã được khởi tạo
      print('Đang lấy thông tin user profile...'); // Debug log
      
      // Lấy token từ ShareService
      final token = await ShareService.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      // Gọi API với token trong header
      final response = await _dio!.get(
        '/api/data-users',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('Response từ API user profile: ${response.data}'); // Debug log
      
      if (response.statusCode == 200) {
        // Lưu thông tin vào ShareService
        if (response.data['success'] == true && response.data['userData'] != null) {
          final userData = response.data['userData'];
          
          // Lưu thông tin user
          await ShareService.saveUserInfo(
            userId: userData['_id'] ?? '',
            email: userData['email'] ?? '',
            userName: '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
            isProfileCompleted: userData['isProfileCompleted'] ?? false,
          );

          // Lưu thông tin chi tiết
          await ShareService.saveUserDetails({
            'firstName': userData['first_name'] ?? '',
            'lastName': userData['last_name'] ?? '',
            'phoneNumber': userData['phone_number'] ?? '',
            'gender': userData['gender'] ?? 'male',
            'isProfileCompleted': userData['isProfileCompleted'] ?? false,
          });
        }
        return response.data;
      }
      throw Exception('Không thể lấy thông tin người dùng');
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  static Future<String?> _getAuthToken() async {
    try {
      // Thử lấy token từ ShareService
      String? token = await ShareService.getToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }

      // Nếu không có trong ShareService, thử lấy từ local storage
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        // Nếu có token trong local storage, đồng bộ lại vào ShareService
        await ShareService.saveToken(token);
        return token;
      }

      return null;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String gender,
    File? profileImage,
  }) async {
    try {
      // Kiểm tra dữ liệu đầu vào
      if (firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty || gender.isEmpty) {
        return {
          'success': false,
          'message': 'Vui lòng điền đầy đủ thông tin'
        };
      }

      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập lại'
        };
      }

      // Tạo FormData với tên trường khớp với NewProfile
      final formData = FormData.fromMap({
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'gender': gender,
        'isProfileCompleted': true,
      });

      // Thêm ảnh nếu có
      if (profileImage != null) {
        String? mimeType = lookupMimeType(profileImage.path);
        formData.files.add(
          MapEntry(
            'profileImage',
            await MultipartFile.fromFile(
              profileImage.path,
              contentType: mimeType != null ? MediaType.parse(mimeType) : null,
            ),
          ),
        );
      }

      // Gọi API
      _initDio();
      final response = await _dio!.put(
        '/api/update-profile',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Update profile response: ${response.data}');

      if (response.statusCode == 200) {
        final userData = response.data['data'] ?? {};
        
        // Lưu thông tin vào ShareService với tên trường khớp với NewProfile
        await ShareService.saveUserInfo(
          userId: userData['_id'] ?? '',
          email: userData['email'] ?? '',
          userName: '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
          isProfileCompleted: true,
        );

        // Lưu thông tin chi tiết với tên trường khớp với NewProfile
        await ShareService.saveUserDetails({
          'first_name': userData['first_name'] ?? '',
          'last_name': userData['last_name'] ?? '',
          'phone_number': userData['phone_number'] ?? '',
          'gender': userData['gender'] ?? 'male',
          'isProfileCompleted': true,
        });

        return {
          'success': true,
          'message': 'Cập nhật thông tin thành công',
          'data': userData,
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Cập nhật thông tin thất bại',
      };
    } catch (e) {
      print('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Lỗi cập nhật thông tin: $e',
      };
    }
  }

  // REVIEW METHODS
  static Future<Map<String, dynamic>?> getProductReviews(String productId, {bool forceRefresh = false}) async {
    try {
      _initDio();
      
      print('Getting reviews for product: $productId');
      print('Force refresh: $forceRefresh');
      
      // Kiểm tra cache nếu không force refresh
      final String cacheKey = 'product_reviews_$productId';
      if (!forceRefresh && _cache.containsKey(cacheKey)) {
        print('Returning cached data for product $productId');
        return _cache[cacheKey];
      }

      final response = await _dio!.get(
        '/api/products/$productId/reviews',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
          validateStatus: (status) => true, // Chấp nhận mọi status code
        ),
      );

      print('API Response status: ${response.statusCode}');
      print('API Response data: ${response.data}');

      // Xử lý response
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // Chuẩn hóa cấu trúc dữ liệu trả về
          final result = {
            'success': true,
            'data': {
              'reviews': responseData['data']?['reviews'] ?? responseData['reviews'] ?? [],
              'summary': {
                'averageRating': responseData['data']?['summary']?['averageRating'] ?? 0.0,
                'totalReviews': responseData['data']?['summary']?['totalReviews'] ?? 0
              }
            }
          };
          
          // Lưu vào cache
          _cache[cacheKey] = result;
          return result;
        }
      }

      // Trả về dữ liệu mặc định cho các trường hợp khác
      return {
        'success': true,
        'data': {
          'reviews': [],
          'summary': {
            'averageRating': 0.0,
            'totalReviews': 0
          }
        }
      };
    } catch (e) {
      print('Error getting product reviews: $e');
      return {
        'success': true,
        'data': {
          'reviews': [],
          'summary': {
            'averageRating': 0.0,
            'totalReviews': 0
          }
        }
      };
    }
  }

  static Future<bool> createProductReview(
    String productId,
    double rating,
    String comment,
    List<String> imagePaths, {
    String? firstName,
    String? lastName,
    String? orderId,
  }) async {
    try {
      _initDio();
      
      // Lấy token từ ShareService
      final token = await ShareService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập để đánh giá sản phẩm');
      }

      print('Creating review for product: $productId');
      print('Rating: $rating');
      print('Comment: $comment');
      print('Images: $imagePaths');
      print('First Name: $firstName');
      print('Last Name: $lastName');
      print('OrderId: $orderId');
      print('Using token: $token');

      Response response;

      if (imagePaths.isNotEmpty) {
        // Nếu có ảnh, gửi dữ liệu dạng multipart
        final formData = FormData.fromMap({
          'productId': productId,
          'rating': rating,
          'comment': comment,
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (orderId != null) 'orderId': orderId,
          'images': [
            for (var path in imagePaths)
              await MultipartFile.fromFile(path, filename: path.split('/').last),
          ],
        });

        response = await _dio!.post(
          '/api/products/reviews',
          data: formData,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            contentType: 'multipart/form-data',
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        );
      } else {
        // Nếu không có ảnh, gửi dữ liệu JSON
        final data = {
          'productId': productId,
          'rating': rating,
          'comment': comment,
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (orderId != null) 'orderId': orderId,
        };

        print('Sending JSON data: $data');
        response = await _dio!.post(
          '/api/products/reviews',
          data: data,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
      }

      print('API Response status: ${response.statusCode}');
      print('API Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Xóa cache để lần sau lấy dữ liệu mới
        final cacheKey = 'product_reviews_$productId';
        _cache.remove(cacheKey);
        
        return true;
      } else {
        print('Error creating review: ${response.data}');
        throw Exception(response.data['message'] ?? 'Có lỗi xảy ra khi tạo đánh giá');
      }
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  // ADDRESS METHODS
  static Future<bool> deleteAddress(String addressId) async {
    try {
      _initDio();
      print('Deleting address $addressId'); // Debug log
      print('Using token: $_authToken'); // Debug log

      final response = await _dio!.delete(
        '/api/addresses/$addressId',
        options: Options(
          headers: getHeaders(),
          validateStatus: (status) => true,
        ),
      );

      print('Delete address response status: ${response.statusCode}'); // Debug log
      print('Delete address response data: ${response.data}'); // Debug log

      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteAddress: $e'); // Debug log
      return false;
    }
  }

  static Future<bool> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    try {
      _initDio();
      print('Updating address $addressId with data: $addressData'); // Debug log
      print('Using token: $_authToken'); // Debug log

      // Đảm bảo dữ liệu đúng format
      final formattedData = {
        'fullName': addressData['fullName'],
        'phoneNumber': addressData['phoneNumber'],
        'street': addressData['street'],
        'city': addressData['city'],
        'district': addressData['district'],
        'ward': addressData['ward'],
        'country': addressData['country'],
        'zipCode': addressData['zipCode'],
        'isDefault': addressData['isDefault'] ?? false,
      };

      print('Formatted update data to send: $formattedData'); // Debug log

      final response = await _dio!.put(
        '/api/addresses/$addressId',
        data: formattedData,
        options: Options(
          headers: getHeaders(),
          validateStatus: (status) => true,
        ),
      );

      print('Update address response status: ${response.statusCode}'); // Debug log
      print('Update address response data: ${response.data}'); // Debug log

      return response.statusCode == 200;
    } catch (e) {
      print('Error in updateAddress: $e'); // Debug log
      return false;
    }
  }

  static Future<Map<String, dynamic>> getAddresses() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/api/AllAddresses',
      );
      
      // Kiểm tra response trực tiếp vì _makeRequest đã trả về Map
      if (response['success'] == true && response['data'] != null) {
        // Chuyển đổi dữ liệu về đúng định dạng
        final List<dynamic> addresses = response['data'] is List ? response['data'] : [];
        return {
          'success': true,
          'data': addresses.map((addr) => {
            '_id': addr['_id']?.toString() ?? '',
            'user_id': addr['user_id']?.toString() ?? '',
            'fullName': addr['fullName']?.toString() ?? '',
            'phoneNumber': addr['phoneNumber']?.toString() ?? '',
            'street': addr['street']?.toString() ?? '',
            'district': addr['district']?.toString() ?? '',
            'city': addr['city']?.toString() ?? '',
            'ward': addr['ward']?.toString() ?? '',
            'country': addr['country']?.toString() ?? '',
            'zipCode': addr['zipCode']?.toString() ?? '',
            'isDefault': addr['isDefault'] == true,
            'createdAt': addr['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
            'updatedAt': addr['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
            '__v': addr['__v'] is num ? addr['__v'] : 0,
          }).toList(),
        };
      }
      return {'success': false, 'message': 'Failed to get addresses'};
    } catch (e) {
      print('Error getting addresses: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      _initDio();
      print('Adding address with data: $addressData'); // Debug log
      print('Using token: $_authToken'); // Debug log

      // Đảm bảo dữ liệu đúng format
      final formattedData = {
        'fullName': addressData['fullName'],
        'phoneNumber': addressData['phoneNumber'],
        'street': addressData['street'],
        'city': addressData['city'],
        'district': addressData['district'],
        'ward': addressData['ward'],
        'country': addressData['country'],
        'zipCode': addressData['zipCode'],
        'isDefault': addressData['isDefault'] ?? false,
      };

      print('Formatted data to send: $formattedData'); // Debug log

      final response = await _dio!.post(
        '/api/addresses',
        data: formattedData,
        options: Options(
          headers: getHeaders(),
          validateStatus: (status) => true,
        ),
      );

      print('Add address response status: ${response.statusCode}'); // Debug log
      print('Add address response data: ${response.data}'); // Debug log

      return response.data;
    } catch (e) {
      print('Error in addAddress: $e'); // Debug log
      rethrow;
    }
  }

  static Future<bool> setDefaultAddress(String addressId) async {
    try {
      _initDio();
      print('Setting address $addressId as default'); // Debug log
      print('Using token: $_authToken'); // Debug log

      final response = await _dio!.put(
        '/api/addresses/$addressId/set-default',
        options: Options(
          headers: getHeaders(),
          validateStatus: (status) => true,
        ),
      );

      print('Set default address response status: ${response.statusCode}'); // Debug log
      print('Set default address response data: ${response.data}'); // Debug log

      return response.statusCode == 200;
    } catch (e) {
      print('Error in setDefaultAddress: $e'); // Debug log
      return false;
    }
  }

  // CAMPING SPOT METHODS
  static Future<List<Map<String, dynamic>>> getCampingSpots() async {
    try {
      final response = await http.get(
        Uri.parse(Config.getFullUrl(Config.campingEndpoints['getAllSpots']!)),
        headers: Config.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Không thể lấy danh sách địa điểm cắm trại');
    } catch (e) {
      print('Error getting camping spots: $e');
      throw Exception('Lỗi kết nối');
    }
  }

  static Future<Map<String, dynamic>> getCampingSpotDetails(String spotId) async {
    try {
      final response = await http.get(
        Uri.parse(Config.getUrlWithParam(
          Config.campingEndpoints['getSpotDetails']!,
          spotId
        )),
        headers: Config.defaultHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Không thể lấy thông tin địa điểm cắm trại');
    } catch (e) {
      print('Error getting camping spot details: $e');
      throw Exception('Lỗi kết nối');
    }
  }

  static Future<List<Map<String, dynamic>>> searchCampingSpots(String query) async {
    try {
      final response = await http.get(
        Uri.parse(Config.getUrlWithQuery(
          Config.campingEndpoints['searchSpots']!,
          {'q': query}
        )),
        headers: Config.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Không thể tìm kiếm địa điểm cắm trại');
    } catch (e) {
      print('Error searching camping spots: $e');
      throw Exception('Lỗi kết nối');
    }
  }

  static Future<List<Map<String, dynamic>>> getCampingSpotReviews(String spotId) async {
    try {
      final response = await http.get(
        Uri.parse(Config.getUrlWithParam(
          Config.campingEndpoints['getSpotReviews']!,
          '$spotId/reviews'
        )),
        headers: Config.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Không thể lấy đánh giá địa điểm');
    } catch (e) {
      print('Error getting spot reviews: $e');
      throw Exception('Lỗi kết nối');
    }
  }

  static Future<bool> createCampingSpotReview(
    String spotId,
    Map<String, dynamic> reviewData
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(Config.getFullUrl(Config.campingEndpoints['createSpotReview']!))
      );

      // Thêm headers
      request.headers.addAll(Config.defaultHeaders);

      // Thêm data
      request.fields['spotId'] = spotId;
      request.fields['rating'] = reviewData['rating'].toString();
      request.fields['comment'] = reviewData['comment'];

      // Thêm hình ảnh nếu có
      if (reviewData['images'] != null) {
        for (String imagePath in reviewData['images']) {
          request.files.add(await http.MultipartFile.fromPath('images', imagePath));
        }
      }

      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating spot review: $e');
      return false;
    }
  }

  // CREDIT CARD METHODS
  static Future<bool> addCard(Map<String, dynamic> cardData) async {
    try {
      _initDio();
      final response = await _dio!.post(
        '/api/AddCards',
        data: cardData,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding card: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getCards() async {
    try {
      final response = await _dio!.get('/api/AllCards');
      print('Raw API Response for cards: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData.containsKey('data') && responseData['data'] is List) {
            return {
              'success': true,
              'data': responseData['data'],
            };
          }
        }
        // Nếu response không có cấu trúc mong đợi
        print('Unexpected response structure: ${response.data}');
      }
      
      return {
        'success': false,
        'message': 'Invalid response format',
      };
    } catch (e, stackTrace) {
      print('Error in getCards: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<bool> deleteCard(String cardId) async {
    try {
      _initDio();
      final response = await _dio!.delete('/api/DeleteCards/$cardId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting card: $e');
      return false;
    }
  }

  // WISHLIST METHODS
  static Future<bool> addToWishlist(String productId) async {
    try {
      _initDio(); // Đảm bảo _dio đã được khởi tạo
      final response = await _dio!.post(
        '/api/wishlist/add',
        data: {'productId': productId},
      );
      print('Add to wishlist response: ${response.data}'); // Debug log
      return response.data['success'] == true;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return false;
    }
  }

  static Future<dynamic> getWishlist() async {
    try {
      _initDio(); // Đảm bảo _dio đã được khởi tạo
      print('Đang kết nối đến API wishlist...');
      final response = await _dio!.get('/api/wishlist');
      print('Response từ API wishlist: ${response.data}');
      return response.data;
    } catch (e) {
      print('Error getting wishlist: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Vui lòng đăng nhập để xem danh sách yêu thích');
        }
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  static Future<bool> removeFromWishlist(String productId) async {
    try {
      _initDio(); // Đảm bảo _dio đã được khởi tạo
      final response = await _dio!.delete('/api/wishlist/$productId');
      print('Remove from wishlist response: ${response.data}'); // Debug log
      return response.data['success'] == true;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }

  // PRODUCT METHODS
  static Future<dynamic> getAllProducts({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    String? sortBy,
    String? orderBy,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      String url;
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Thêm các tham số tìm kiếm và lọc
      if (search != null) queryParams['search'] = search;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (orderBy != null) queryParams['orderBy'] = orderBy;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

      // Nếu categoryId là null hoặc 'all', lấy tất cả sản phẩm
      if (categoryId == null || categoryId == 'all') {
        url = '${Config.baseUrl}/api/products';
        final uri = Uri.parse(url).replace(queryParameters: queryParams);
        url = uri.toString();
      } else {
        // Nếu có categoryId khác 'all', lấy sản phẩm theo danh mục
        url = '${Config.baseUrl}/api/categories/$categoryId/products';
        final uri = Uri.parse(url).replace(queryParameters: queryParams);
        url = uri.toString();
      }

      print('Đang kết nối đến API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: Config.defaultHeaders,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Kết nối bị timeout khi gọi API getAllProducts');
          throw Exception('Kết nối bị timeout. Vui lòng kiểm tra lại kết nối mạng và máy chủ API.');
        },
      );

      print('Phản hồi từ API: ${response.statusCode} - ${response.body.substring(0, 100)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Nếu là tất cả sản phẩm
          if (categoryId == null || categoryId == 'all') {
            return {
              'success': true,
              'data': data['data']['products'] ?? []
            };
          }
          // Nếu là sản phẩm theo danh mục
          return {
            'success': true,
            'data': {
              'products': data['data']['products'] ?? []
            }
          };
        }
        return data;
      } else {
        print('Lỗi API: ${response.statusCode} - ${response.body}');
        throw Exception('Không thể lấy danh sách sản phẩm (${response.statusCode})');
      }
    } catch (e) {
      print('Error getting products: $e');
      if (e.toString().contains('SocketException')) {
        print('Lỗi SocketException: Không thể kết nối đến máy chủ');
        throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại địa chỉ IP và cổng của máy chủ API.');
      } else if (e.toString().contains('timeout')) {
        print('Lỗi timeout: Kết nối bị timeout');
        throw Exception('Kết nối bị timeout. Vui lòng kiểm tra lại kết nối mạng và máy chủ API.');
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  static Future<dynamic> getAllCategories() async {
    try {
      print('Đang kết nối đến API: ${Config.getFullUrl(Config.productEndpoints['getAllCategories']!)}');
      final response = await http.get(
        Uri.parse(Config.getFullUrl(Config.productEndpoints['getAllCategories']!)),
        headers: Config.defaultHeaders,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Kết nối bị timeout khi gọi API getAllCategories');
          throw Exception('Kết nối bị timeout. Vui lòng kiểm tra lại kết nối mạng và máy chủ API.');
        },
      );

      print('Phản hồi từ API: ${response.statusCode} - ${response.body.substring(0, 100)}...');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Trả về dữ liệu gốc để widget xử lý
        return data;
      } else {
        print('Lỗi API: ${response.statusCode} - ${response.body}');
        throw Exception('Không thể lấy danh sách danh mục (${response.statusCode})');
      }
    } catch (e) {
      print('Error getting categories: $e');
      if (e.toString().contains('SocketException')) {
        print('Lỗi SocketException: Không thể kết nối đến máy chủ');
        throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại địa chỉ IP và cổng của máy chủ API.');
      } else if (e.toString().contains('timeout')) {
        print('Lỗi timeout: Kết nối bị timeout');
        throw Exception('Kết nối bị timeout. Vui lòng kiểm tra lại kết nối mạng và máy chủ API.');
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  static Future<dynamic> getProductDetails(String productId) async {
    try {
      _initDio();
      print('Getting product details for ID: $productId');
      
      final response = await _dio!.get(
        '/api/products/$productId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
          validateStatus: (status) {
            return true; // Accept all status codes for proper error handling
          },
        ),
      );

      print('Product details API Response status: ${response.statusCode}');
      print('Product details API Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> && 
            response.data['success'] == true && 
            response.data['data'] != null) {
          // Ensure all required fields are present with correct types
          final productData = response.data['data'];
          return {
            'success': true,
            'data': {
              ...productData,
              'price': (productData['price'] ?? 0.0).toDouble(),
              'originalPrice': (productData['originalPrice'] ?? 0.0).toDouble(),
              'discount': productData['discount'] ?? 0,
              'stockQuantity': productData['stockQuantity'] ?? 0,
              'sold': productData['sold'] ?? 0,
              'rating': (productData['rating'] ?? 0.0).toDouble(),
              'review_count': productData['review_count'] ?? 0,
            }
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to get product details'
      };
    } catch (e) {
      print('Error getting product details: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse(Config.getUrlWithParam(
          Config.productEndpoints['getProductsByCategory']!,
          '$categoryId/products'
        )),
        headers: Config.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Không thể lấy sản phẩm theo danh mục');
    } catch (e) {
      print('Error getting products by category: $e');
      throw Exception('Lỗi kết nối');
    }
  }

  // CART METHODS
  static Future<bool> addToCart(String productId, int quantity) async {
    try {
      _initDio(); // Đảm bảo _dio đã được khởi tạo
      print('Đang thêm vào giỏ hàng - ProductId: $productId, Quantity: $quantity');
      final response = await _dio!.post(
        '/api/cart/add',
        data: {
          'productId': productId,
          'quantity': quantity,
        },
      );
      print('Add to cart response: ${response.data}');
      return response.data['success'] == true;
    } catch (e) {
      print('Error adding to cart: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Vui lòng đăng nhập để thêm vào giỏ hàng');
        }
        print('DioError response: ${e.response?.data}');
      }
      return false;
    }
  }

  static Future<dynamic> getCart() async {
    try {
      _initDio();
      if (_dio == null) throw Exception('Dio chưa được khởi tạo');
      
      final response = await _dio!.get('/api/cart');
      print('Get cart response: ${response.data}');
      return response.data;
    } catch (e) {
      print('Error getting cart: $e');
      throw Exception('Không thể lấy giỏ hàng');
    }
  }

  static Future<bool> updateCartItem(String productId, int quantity) async {
    try {
      _initDio();
      if (_dio == null) throw Exception('Dio chưa được khởi tạo');
      
      final response = await _dio!.put(
        '/api/cart/update',
        data: {
          'productId': productId,
          'quantity': quantity,
        },
      );
      print('Update cart response: ${response.data}');
      return response.data['success'] == true;
    } catch (e) {
      print('Error updating cart: $e');
      return false;
    }
  }

  static Future<bool> removeFromCart(String productId) async {
    try {
      _initDio();
      if (_dio == null) throw Exception('Dio chưa được khởi tạo');
      
      final response = await _dio!.delete('/api/cart/$productId');
      print('Remove from cart response: ${response.data}');
      return response.data['success'] == true;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  static Future<bool> clearCart() async {
    try {
      _initDio();
      if (_dio == null) throw Exception('Dio chưa được khởi tạo');
      
      final response = await _dio!.delete('/api/cart/clear');
      print('Clear cart response: ${response.data}');
      return response.data['success'] == true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  static Future<dynamic> searchProducts({
    String? query,
    String? category,
    String? sortBy,
    int? minPrice,
    int? maxPrice,
  }) async {
    try {
      _initDio();
      if (_dio == null) throw Exception('Dio chưa được khởi tạo');
      
      final endpoint = '/api/products/search';
      final response = await _dio!.get(endpoint, 
        queryParameters: {
          if (query != null) 'query': query,
          if (category != null) 'category': category,
          if (sortBy != null) 'sortBy': sortBy,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
        },
      );
      print('Search products response: ${response.data}');
      return response.data;
    } catch (e) {
      print('Error searching products: $e');
      throw Exception('Không thể tìm kiếm sản phẩm');
    }
  }

  static Future<Map<String, dynamic>> getCartItems(Set<String> productIds) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/cart/items',
        method: 'POST',
        body: {
          'productIds': productIds.toList(),
        },
      );

      // Kiểm tra và chuyển đổi dữ liệu
      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': {
            'items': response['data']['items'] ?? [],
            'shippingFee': (response['data']['shippingFee'] ?? 30.0).toDouble(),
            'subTotal': (response['data']['subTotal'] ?? 0.0).toDouble(),
            'total': (response['data']['total'] ?? 0.0).toDouble(),
          },
        };
      }
      return {
        'success': false,
        'message': 'Không thể lấy thông tin giỏ hàng',
      };
    } catch (e) {
      print('Error getting cart items: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      _initDio();
      
      // Lấy token từ ShareService
      String? token = await ShareService.getToken();
      if (token == null || token.isEmpty) {
        print('Token is null or empty');
        return {
          'success': false,
          'message': 'Không tìm thấy token xác thực',
        };
      }

      print('Creating order with data: $orderData');
      print('Using token: $token');

      final response = await _dio!.post(
        '/api/orders/create',
        data: orderData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('Create order response: ${response.data}');
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Tạo đơn hàng thành công',
          'data': response.data['order']
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Không thể tạo đơn hàng',
        };
      }
    } catch (e) {
      print('Error creating order: $e');
      return {
        'success': false,
        'message': 'Không thể tạo đơn hàng: $e'
      };
    }
  }

  static Future<dynamic> _makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    try {
      _initDio();
      
      // Sử dụng token hiện tại từ APIService
      if (_authToken != null) {
        _dio!.options.headers['Authorization'] = 'Bearer $_authToken';
      }

      Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio!.get(endpoint);
          break;
        case 'POST':
          response = await _dio!.post(endpoint, data: body);
          break;
        case 'PUT':
          response = await _dio!.put(endpoint, data: body);
          break;
        case 'DELETE':
          response = await _dio!.delete(endpoint);
          break;
        default:
          throw Exception('Phương thức không được hỗ trợ');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data['message'] != null) {
          throw Exception(e.response?.data['message']);
        }
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  static Future<Map<String, dynamic>?> getOrders() async {
    try {
      _initDio();
      
      // Lấy token từ ShareService
      String? token = await ShareService.getToken();
      if (token == null || token.isEmpty) {
        print('Token is null or empty');
        return {
          'success': false,
          'message': 'Không tìm thấy token xác thực',
          'data': []
        };
      }

      print('Calling getOrders API with token: $token');
      final response = await _dio!.get(
        '/api/orders/my-orders',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('GetOrders Response: ${response.data}');
      return response.data;
    } catch (e) {
      print('Error getting orders: $e');
      return {
        'success': false,
        'message': 'Lỗi khi lấy danh sách đơn hàng: $e',
        'data': []
      };
    }
  }

  static Future<Map<String, dynamic>> returnOrder(String orderId) async {
    try {
      _initDio();
      final response = await _dio!.put(
        '/api/orders/$orderId/return',
        options: Options(headers: getHeaders()),
      );
      
      return {
        'success': response.statusCode == 200,
        'message': response.data['message'] ?? 'Đã gửi yêu cầu hoàn trả',
        'data': response.data
      };
    } catch (e) {
      print('Error returning order: $e');
      return {
        'success': false,
        'message': 'Không thể gửi yêu cầu hoàn trả: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> confirmDelivery(String orderId) async {
    try {
      print('Confirming delivery for order: $orderId');
      
      // Kiểm tra đăng nhập
      final isLoggedIn = await ShareService.isLoggedIn();
      if (!isLoggedIn) {
        print('User not logged in');
        return {
          'success': false,
          'message': 'User not logged in'
        };
      }

      // Lấy token
      final token = await ShareService.getToken();
      if (token == null || token.isEmpty) {
        print('Token is null or empty');
        return {
          'success': false,
          'message': 'No token, authorization denied'
        };
      }

      print('Token retrieved successfully');
      
      // Gọi API cập nhật trạng thái đơn hàng
      final response = await _dio!.put(
        '/api/orders/$orderId/confirm-delivery',
        data: {
          'delivery_status': 'Delivered',
          'waiting_confirmation': false
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('API Response: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Order confirmed as delivered successfully',
          'data': response.data
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to confirm delivery: ${response.data['message'] ?? 'Unknown error'}'
        };
      }
    } catch (e) {
      print('Error confirming delivery: $e');
      return {
        'success': false,
        'message': 'Error confirming delivery: $e'
      };
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static void clearCache() {
    _cache = {};
  }

  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      _initDio();
      
      // Lấy token từ ShareService
      String? token = await ShareService.getToken();
      if (token == null || token.isEmpty) {
        print('Token is null or empty');
        return {
          'success': false,
          'message': 'Không tìm thấy token xác thực',
        };
      }

      print('Cancelling order with ID: $orderId');
      print('Using token: $token');

      final response = await _dio!.delete(
        '/api/orders/$orderId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('Cancel order response: ${response.data}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Đã hủy đơn hàng thành công',
          'data': response.data
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Không thể hủy đơn hàng',
        };
      }
    } catch (e) {
      print('Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Không thể hủy đơn hàng: $e'
      };
    }
  }
} 