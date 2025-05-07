import 'package:CampGo/models/user_model.dart';
import 'package:CampGo/services/share_service.dart';
import 'package:CampGo/config/config.dart';
import 'package:CampGo/models/login_response_model.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  static String? _lastProductRoute;
  static Map<String, dynamic>? _lastProductData;
  static Dio _dio = Dio();
  static String get baseUrl => Config.baseUrl;
  static const String _tokenKey = 'auth_token';

  // Lưu thông tin sản phẩm trước khi yêu cầu đăng nhập
  static void saveLastProductInfo(String route, Map<String, dynamic> data) {
    print("Saving product info: route=$route, data=$data"); // Debug log
    _lastProductRoute = route;
    _lastProductData = Map<String, dynamic>.from(data); // Create a deep copy
  }

  // Lấy và xóa thông tin sản phẩm đã lưu
  static Map<String, dynamic>? getAndClearLastProductInfo() {
    if (_lastProductRoute == null || _lastProductData == null) {
      return null;
    }
    
    final data = {
      'route': _lastProductRoute,
      'data': Map<String, dynamic>.from(_lastProductData!),
    };
    
    // Clear the stored data
    _lastProductRoute = null;
    _lastProductData = null;
    
    print("Retrieving product info: $data"); // Debug log
    return data;
  }

  static Future<bool> isLoggedIn() async {
    try {
      // Thử lấy token từ ShareService
      String? token = await ShareService.getToken();
      print('Token from ShareService: $token');
      
      if (token != null && token.isNotEmpty) {
        return true;
      }

      // Nếu không có trong ShareService, thử lấy từ local storage
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_tokenKey);
      print('Token from local storage: $token');
      
      if (token != null && token.isNotEmpty) {
        // Nếu có token trong local storage, đồng bộ lại vào ShareService
        await ShareService.saveToken(token);
        return true;
      }

      return false;
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  static Future<void> logout(BuildContext context) async {
    try {
      await ShareService.clearUserData();
      // Navigate to login page and clear all routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  static Future<void> checkProtectedRoute(BuildContext context) async {
    bool isLogged = await isLoggedIn();
    if (!isLogged) {
      // Pop current route first
      Navigator.of(context).pop();
      // Then show login dialog
      showLoginDialog(context);
      return;
    }
  }

  static Future<void> requireLogin(BuildContext context) async {
    if (!await isLoggedIn()) {
      showLoginDialog(context);
    }
  }

  static void showLoginDialog(BuildContext context, {String? returnRoute, Map<String, dynamic>? returnData}) {
    if (returnRoute != null && returnData != null) {
      saveLastProductInfo(returnRoute, returnData);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to access this feature'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
            TextButton(
              child: const Text('Login'),
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await _dio.post(
        '${Config.baseUrl}/api/auth/register',
        data: {
          'user_name': name,
          'email': email,
          'password': password,
          'isProfileCompleted': false,
          'isAccountVerified': false,
          'verifyOtp': '',
          'verifyOtpExpireAt': 0,
          'resetOtp': '',
          'resetOtpExpireAt': '0',
          '__v': 0
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Register response: ${response.data}');

      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'];
          print('Register success, saving token: $token');
          
          // Lưu token vào ShareService
          await ShareService.saveToken(token);
          
          return {
            'success': true,
            'message': data['message'] ?? 'Đăng ký thành công',
            'data': data
          };
        }
        
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Đăng ký thất bại'
        };
      }

      return {
        'success': false,
        'message': 'Đăng ký thất bại: Response không hợp lệ'
      };
    } catch (e) {
      print('Register error: $e');
      if (e is DioException && e.response?.data != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Đăng ký thất bại'
        };
      }
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e'
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '${Config.baseUrl}/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('Login response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'];
          print('Login success, saving token: $token');
          
          // Lưu token vào cả ShareService và local storage
          await ShareService.saveToken(token);
          await setToken(token);
          
          // Lưu thông tin user
          final user = data['user'] ?? {};
          await ShareService.saveUserInfo(
            userId: user['_id'] ?? '',
            email: user['email'] ?? '',
            userName: user['user_name'] ?? '',
            isProfileCompleted: user['isProfileCompleted'] ?? false,
          );

          // Lưu chi tiết user
          await ShareService.saveUserDetails(user);

          print('User info saved successfully');

          return {
            'success': true,
            'message': data['message'] ?? 'Đăng nhập thành công',
            'data': data,
            'isProfileCompleted': user['isProfileCompleted'] ?? false,
            'userName': user['user_name'] ?? '',
            'userEmail': user['email'] ?? ''
          };
        }
      }
      
      final message = response.data['message'] as String?;
      return {
        'success': false,
        'message': message ?? 'Đăng nhập thất bại'
      };
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e'
      };
    }
  }

  Future<Map<String, dynamic>> sendVerifyOTP(String email) async {
    try {
      String? token = await ShareService.getToken();
      print('Token for sending OTP: $token');

      if (token == null) {
        print('No token found for sending OTP');
        return {
          'success': false,
          'message': 'Không tìm thấy token xác thực',
        };
      }

      return await sendVerifyOTPWithToken(email, token);
    } catch (e) {
      print('Send OTP error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> sendVerifyOTPWithToken(String email, String token) async {
    try {
      print('Sending OTP with token: $token');

      final response = await http.post(
        Uri.parse(Config.getFullUrl(Config.authEndpoints['sendVerifyOTP']!)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
        }),
      );

      print('Send OTP URL: ${Config.getFullUrl(Config.authEndpoints['sendVerifyOTP']!)}');
      print('Send OTP headers: ${response.request?.headers}');
      print('Send OTP response status: ${response.statusCode}');
      print('Send OTP response body: ${response.body}');

      final responseData = json.decode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Send OTP failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Lỗi gửi mã OTP',
        };
      }

      return responseData;
    } catch (e) {
      print('Send OTP error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      String? token = await ShareService.getToken();
      print('Token for verifying OTP: $token');

      if (token == null) {
        print('No token found for verifying OTP');
        return {
          'success': false,
          'message': 'Không tìm thấy token xác thực',
        };
      }

      final response = await http.post(
        Uri.parse(Config.getFullUrl(Config.authEndpoints['verifyEmail']!)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      print('Verify OTP URL: ${Config.getFullUrl(Config.authEndpoints['verifyEmail']!)}');
      print('Verify OTP headers: ${response.request?.headers}');
      print('Verify OTP response status: ${response.statusCode}');
      print('Verify OTP response body: ${response.body}');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Nếu xác thực thành công, cập nhật token mới nếu có
        if (responseData['token'] != null) {
          await ShareService.saveToken(responseData['token']);
          print('New token saved after OTP verification');
        }
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Xác thực OTP thất bại',
        };
      }
    } catch (e) {
      print('Verify OTP error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  Future<String?> getToken() async {
    try {
      // Thử lấy token từ ShareService trước
      String? token = await ShareService.getToken();
      print('Token from ShareService: $token');
      
      if (token != null && token.isNotEmpty) {
        return token;
      }

      // Nếu không có trong ShareService, thử lấy từ local storage
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_tokenKey);
      print('Token from local storage: $token');
      
      if (token != null && token.isNotEmpty) {
        // Nếu có token trong local storage, đồng bộ lại vào ShareService
        await ShareService.saveToken(token);
        return token;
      }

      // Nếu vẫn không có token, thử lấy từ response của login
      final userInfo = await ShareService.getUserInfo();
      if (userInfo != null && userInfo['token'] != null) {
        token = userInfo['token'];
        await ShareService.saveToken(token!);
        return token;
      }

      // Nếu vẫn không có token, thử lấy từ response của login trong data
      final userDetails = await ShareService.getUserDetails();
      if (userDetails != null && userDetails['token'] != null) {
        token = userDetails['token'];
        await ShareService.saveToken(token!);
        return token;
      }

      print('No token found in any storage');
      return null;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Future<void> setToken(String token) async {
    try {
      // Lưu token vào cả ShareService và local storage
      await ShareService.saveToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error setting token: $e');
    }
  }

  Future<void> clearToken() async {
    try {
      // Xóa token từ cả ShareService và local storage
      await ShareService.clearUserData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  Future<void> setLoginDetails(LoginResponseModel loginResponse) async {
    if (loginResponse.accesstoken != null) {
      await setToken(loginResponse.accesstoken!);
    }
    await ShareService.saveUserInfo(
      userId: loginResponse.id ?? '',
      email: loginResponse.email ?? '',
      userName: loginResponse.user_name ?? '',
      isProfileCompleted: loginResponse.isProfileCompleted ?? false,
    );
  }

  Future<Map<String, dynamic>> sendResetOTP(String email) async {
    try {
      final response = await _dio.post(
        '${Config.baseUrl}/api/auth/send-reset-otp',
        data: {'email': email},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Send Reset OTP response: ${response.data}'); // Debug log
      return response.data;
    } catch (e) {
      print('Send Reset OTP error: $e'); // Debug log
      if (e is DioException && e.response?.data != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Lỗi gửi mã OTP'
        };
      }
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e'
      };
    }
  }

  Future<Map<String, dynamic>> verifyResetOTP(String email, String otp) async {
    try {
      final response = await _dio.post(
        '${Config.baseUrl}/api/auth/verify-reset-otp',
        data: {
          'email': email,
          'otp': otp,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Verify Reset OTP response: ${response.data}'); // Debug log
      return response.data;
    } catch (e) {
      print('Verify Reset OTP error: $e'); // Debug log
      if (e is DioException && e.response?.data != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Lỗi xác thực OTP'
        };
      }
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e'
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy token xác thực'
        };
      }

      final response = await _dio.post(
        '${Config.baseUrl}/api/auth/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Reset password response: ${response.data}'); // Debug log
      
      // Xóa token sau khi đặt lại mật khẩu thành công
      if (response.data['success'] == true) {
        await ShareService.clearUserData();
      }
      
      return response.data;
    } catch (e) {
      print('Reset password error: $e'); // Debug log
      if (e is DioException && e.response?.data != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Lỗi đặt lại mật khẩu'
        };
      }
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e'
      };
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await ShareService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập lại',
        };
      }

      final response = await _dio.put(
        '${Config.baseUrl}/api/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Change password request data: ${{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': newPassword,
      }}');
      print('Change password response: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Đổi mật khẩu thành công',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Đổi mật khẩu thất bại',
        };
      }
    } on DioException catch (e) {
      print('Error changing password: ${e.message}');
      print('Error response: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Có lỗi xảy ra khi đổi mật khẩu',
      };
    } catch (e) {
      print('Unexpected error: $e');
      return {
        'success': false,
        'message': 'Có lỗi xảy ra khi đổi mật khẩu',
      };
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      await ShareService.saveUserInfo(
        userId: profileData['_id'] ?? '',
        email: profileData['email'] ?? '',
        userName: profileData['user_name'] ?? '',
        isProfileCompleted: profileData['isProfileCompleted'] ?? false,
      );
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Lỗi cập nhật thông tin người dùng');
    }
  }

  Future<void> updateProfileCompletionStatus(bool isCompleted) async {
    try {
      String? token = await getToken();
      if (token == null) {
        throw Exception('Không có token xác thực. Vui lòng đăng nhập lại.');
      }

      final response = await _dio.put(
        '${Config.baseUrl}/api/users/update-profile-completion',
        data: {
          'isProfileCompleted': isCompleted,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Cập nhật thông tin user trong ShareService
        final userInfo = await ShareService.getUserInfo();
        if (userInfo != null) {
          await ShareService.saveUserInfo(
            userId: userInfo['userId'] ?? '',
            email: userInfo['email'] ?? '',
            userName: userInfo['userName'] ?? '',
            isProfileCompleted: isCompleted,
          );
        }
      } else {
        throw Exception('Lỗi cập nhật trạng thái profile');
      }
    } catch (e) {
      print('Error updating profile completion status: $e');
      throw Exception('Lỗi cập nhật trạng thái profile: $e');
    }
  }

  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String gender,
    String? profileImagePath,
  }) async {
    try {
      String? token = await ShareService.getToken();
      
      if (token == null) {
        throw Exception('Không thể lấy token. Vui lòng đăng nhập lại.');
      }

      // Tạo FormData với tên trường khớp với MongoDB
      final formData = FormData.fromMap({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'isProfileCompleted': true, // Thêm trường này để cập nhật trạng thái
      });

      // Thêm ảnh nếu có
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'profileImage',
            await MultipartFile.fromFile(profileImagePath),
          ),
        );
      }

      // Gọi API với URL đúng
      final response = await _dio.put(
        '${Config.baseUrl}/api/update-profile',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final userData = response.data['data'] ?? {};
        
        // Cập nhật thông tin user trong ShareService
        await ShareService.saveUserInfo(
          userId: userData['_id'] ?? '',
          email: userData['email'] ?? '',
          userName: userData['userName'] ?? '',
          isProfileCompleted: true, // Đảm bảo cập nhật trạng thái
        );

        // Lưu thông tin chi tiết
        await ShareService.saveUserDetails({
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'phoneNumber': userData['phoneNumber'] ?? '',
          'gender': userData['gender'] ?? 'male',
          'isProfileCompleted': true,
        });

        // Tạo và trả về UserProfile
        return UserProfile(
          id: userData['_id'] ?? '',
          firstName: userData['firstName'] ?? '',
          lastName: userData['lastName'] ?? '',
          email: userData['email'] ?? '',
          phoneNumber: userData['phoneNumber'] ?? '',
          profileImage: userData['profileImage'],
          isProfileCompleted: true,
          gender: userData['gender'] ?? 'male',
        );
      } else {
        throw Exception('Cập nhật thông tin thất bại: ${response.data['message'] ?? 'Không có thông báo lỗi'}');
      }
    } catch (e) {
      print('Lỗi khi cập nhật profile: $e');
      throw Exception('Cập nhật thông tin thất bại: $e');
    }
  }
}
