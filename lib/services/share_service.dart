import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  static const String _tokenKey = 'token';
  static const String _resetTokenKey = 'reset_token';
  static const String _userInfoKey = 'user_info';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('Token saved: $token');
  }

  static Future<void> saveResetToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resetTokenKey, token);
    print('Reset token saved: $token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Token loaded from storage: $token');
    return token;
  }

  static Future<String?> getResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_resetTokenKey);
    print('Reset token loaded from storage: $token');
    return token;
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('Token removed');
  }

  static Future<void> removeResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resetTokenKey);
    print('Reset token removed');
  }

  static Future<void> saveUserInfo({
    required String userId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInfoKey, jsonEncode({
      'userId': userId,
      'email': email,
    }));
    print('User info saved: userId=$userId, email=$email');
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfo = prefs.getString(_userInfoKey);
    if (userInfo == null) return null;
    return jsonDecode(userInfo);
  }

  static Future<void> clearLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userInfoKey);
    print('Login details cleared');
  }
} 