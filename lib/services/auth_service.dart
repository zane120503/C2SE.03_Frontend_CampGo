import 'package:CampGo/utils/share_service.dart';
import 'package:flutter/material.dart';

class AuthService {
  static String? _lastProductRoute;
  static Map<String, dynamic>? _lastProductData;

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
}
