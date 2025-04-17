import 'package:CampGo/services/share_service.dart';
import 'package:CampGo/config/config.dart';
import 'package:CampGo/models/login_response.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class AuthService {
  static String? _lastProductRoute;
  static Map<String, dynamic>? _lastProductData;
  static Dio _dio = Dio();
  static String get baseUrl => Config.baseUrl;

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
      String? token = await ShareService.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  static Future<void> logout(BuildContext context) async {
    try {
      await ShareService.clearLoginDetails();
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

      // Kiểm tra response.data có phải là Map không
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        
        // Nếu có token và success là true
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'];
          print('Register success, saving token: $token');
          await ShareService.saveToken(token);
          return {
            'success': true,
            'message': data['message'] ?? 'Đăng ký thành công',
            'data': data
          };
        }
        
        // Nếu không có token nhưng có message
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

      if (response.statusCode == 200) {
        final token = response.data['token'];
        print('Login success, saving token: $token');
        await ShareService.saveToken(token);
        return {
          'success': true,
          'message': 'Đăng nhập thành công',
          'data': response.data
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Đăng nhập thất bại'
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
    return ShareService.getToken();
  }

  Future<void> setLoginDetails(LoginResponseModel loginResponse) async {
    await ShareService.saveToken(loginResponse.accesstoken);
    await ShareService.saveUserInfo(
      userId: loginResponse.userId,
      email: loginResponse.email,
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
      String? resetToken = await ShareService.getResetToken();
      if (resetToken == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy reset token'
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
            'Authorization': 'Bearer $resetToken',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Reset password response: ${response.data}'); // Debug log
      
      // Xóa reset token sau khi đặt lại mật khẩu thành công
      if (response.data['success'] == true) {
        await ShareService.removeResetToken();
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
}
