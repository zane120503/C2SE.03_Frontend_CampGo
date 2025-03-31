import 'dart:convert';
import 'package:CampGo/model/login_response_model.dart';
import 'package:api_cache_manager/api_cache_manager.dart';
import 'package:api_cache_manager/models/cache_db_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String KEY_NAME = "login_key";

// Assuming you have a global navigator key defined somewhere in your app

class ShareService {
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
    try {
      if (await isLoggedIn()) {
        var cacheData = await APICacheManager().getCacheData(KEY_NAME);
        var loginDetails = loginResponseJson(cacheData.syncData);
        return loginDetails.accesstoken;
      }
      return null;
    } catch (e) {
      print("Error getting token: $e");
      return null;
    }
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
    try {
      await APICacheManager().deleteCache(KEY_NAME);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored preferences
    } catch (e) {
      print("Error clearing login details: $e");
      rethrow;
    }
  }
}
