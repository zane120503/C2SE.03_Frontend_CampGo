import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String emailKey = 'email';
  static const String isProfileCompletedKey = 'is_profile_completed';
  static const String userNameKey = 'user_name';
  static const String resetTokenKey = 'reset_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    print('Token saved: $token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    print('Token loaded from storage: $token');
    return token;
  }

  static Future<void> saveResetToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(resetTokenKey, token);
    print('Reset token saved: $token');
  }

  static Future<String?> getResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(resetTokenKey);
    print('Reset token loaded from storage: $token');
    return token;
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    print('Token removed');
  }

  static Future<void> removeResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(resetTokenKey);
    print('Reset token removed');
  }

  static Future<void> saveUserInfo({
    String? userId,
    String? email,
    bool isProfileCompleted = false,
    String? userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) await prefs.setString(userIdKey, userId);
    if (email != null) await prefs.setString(emailKey, email);
    await prefs.setBool(isProfileCompletedKey, isProfileCompleted);
    if (userName != null) {
      await prefs.setString(userNameKey, userName);
    }
    print('User info saved: userId=$userId, email=$email');
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(userIdKey),
      'email': prefs.getString(emailKey),
      'isProfileCompleted': prefs.getBool(isProfileCompletedKey) ?? false,
      'userName': prefs.getString(userNameKey),
    };
  }

  static Future<void> clearLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userIdKey);
    await prefs.remove(emailKey);
    await prefs.remove(isProfileCompletedKey);
    await prefs.remove(userNameKey);
    await prefs.remove(resetTokenKey);
    print('Login details cleared');
  }
} 