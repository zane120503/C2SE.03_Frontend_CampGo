import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userInfoKey = 'user_info';
  static const String _userDetailsKey = 'user_details';

  // Cache token trong memory
  static String? _cachedToken;

  static Future<void> saveToken(String token) async {
    try {
      _cachedToken = token; // Lưu vào cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('Token saved to cache and storage: $token');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      // Thử lấy từ cache trước
      if (_cachedToken != null) {
        print('Return cached token: $_cachedToken');
        return _cachedToken;
      }

      // Nếu không có trong cache, thử lấy từ local storage
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);
      print('Token loaded from storage: $_cachedToken');
      return _cachedToken;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String userName,
    required bool isProfileCompleted,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfo = {
        'userId': userId,
        'email': email,
        'userName': userName,
        'isProfileCompleted': isProfileCompleted,
      };
      await prefs.setString(_userInfoKey, jsonEncode(userInfo));
      print('User info saved: $userInfo');
    } catch (e) {
      print('Error saving user info: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString(_userInfoKey);
      if (userInfoString != null) {
        final userInfo = jsonDecode(userInfoString);
        print('User info loaded: $userInfo');
        return userInfo;
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  static Future<void> saveUserDetails(Map<String, dynamic> details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDetailsKey, jsonEncode(details));
      print('User details saved: $details');
    } catch (e) {
      print('Error saving user details: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final detailsString = prefs.getString(_userDetailsKey);
      if (detailsString != null) {
        final details = jsonDecode(detailsString);
        print('User details loaded: $details');
        return details;
      }
      return null;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  static Future<void> clearUserData() async {
    try {
      _cachedToken = null; // Xóa token khỏi cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userInfoKey);
      await prefs.remove(_userDetailsKey);
      print('All user data cleared');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      print('Checking login status with token: $token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
} 