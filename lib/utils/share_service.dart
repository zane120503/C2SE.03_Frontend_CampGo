import 'dart:convert';
import 'package:CampGo/model/login_response_model.dart';
import 'package:api_cache_manager/api_cache_manager.dart';
import 'package:api_cache_manager/models/cache_db_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String KEY_NAME = "login_key";

// Assuming you have a global navigator key defined somewhere in your app

class ShareService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // Cache token trong memory
  static String? _cachedToken;

  static Future<bool> isLoggedIn() async {
    try {
      var isCacheKeyExist = await APICacheManager().isAPICacheKeyExist(KEY_NAME);
      if (isCacheKeyExist) {
        var cacheData = await APICacheManager().getCacheData(KEY_NAME);
        var loginDetails = loginResponseJson(cacheData.syncData);
        // Kiểm tra thêm token có hợp lệ không
        return loginDetails.accesstoken != null && loginDetails.accesstoken!.isNotEmpty;
      }
      return false;
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) {
      print('Return cached token: $_cachedToken');
      return _cachedToken;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    print('Token loaded from storage: $_cachedToken');
    return _cachedToken;
  }

  static Future<void> setLoginDetails(LoginResponseModel model) async {
    try {
      // Xóa cache cũ trước khi lưu mới
      await APICacheManager().deleteCache(KEY_NAME);
      
      APICacheDBModel cacheDBModel = APICacheDBModel(
        key: KEY_NAME,
        syncData: jsonEncode(model.toJson()),
      );
      await APICacheManager().addCacheData(cacheDBModel);
    } catch (e) {
      print("Error setting login details: $e");
    }
  }

  static Future<void> clearLoginDetails() async {
    _cachedToken = null; // Xóa token khỏi cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    print('All login details cleared');
  }

  // Lưu token
  static Future<void> saveToken(String token) async {
    _cachedToken = token; // Lưu vào cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('Token saved to cache and storage: $token');
  }

  // Lấy ID người dùng
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Lấy email người dùng
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Lưu thông tin người dùng
  static Future<void> saveUserInfo({
    required String userId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    print('User info saved - userId: $userId, email: $email');
  }
}
