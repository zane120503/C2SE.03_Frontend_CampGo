import 'dart:io';

class Config {
  // Base URL Configuration
  static const String apiURL = "192.168.1.211:3000";  // IP của máy chạy backend
  static const bool useHttps = false;
  static String get baseUrl => "${useHttps ? 'https' : 'http'}://$apiURL";

  // Platform specific configuration
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isWeb => !Platform.isIOS && !Platform.isAndroid;

  // API Request Configuration
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Access-Control-Allow-Origin': '*',
    if (isIOS) 'X-Platform': 'iOS',
    if (isAndroid) 'X-Platform': 'Android',
    if (isWeb) 'X-Platform': 'Web',
  };

  // Timeout Settings
  static const int connectionTimeout = 30000;  // 30 seconds
  static const int receiveTimeout = 30000;     // 30 seconds

  // Retry Settings
  static const int maxRetries = 3;
  static const int retryDelay = 1000; // 1 second

  // Auth API Endpoints
  static const Map<String, String> authEndpoints = {
    'register': '/api/auth/register',
    'login': '/api/auth/login',
    'logout': '/api/auth/logout',
    'sendVerifyOTP': '/api/auth/send-verify-otp',
    'verifyEmail': '/api/auth/verify-email',
    'isAuth': '/api/auth/is-auth',
    'sendResetOTP': '/api/auth/send-Reset-OTP',
    'verifyResetOTP': '/api/auth/verify-reset-otp',
    'resetPassword': '/api/auth/reset-password',
    'changePassword': '/api/auth/change-password',
  };

  // User API Endpoints
  static const Map<String, String> userEndpoints = {
    'userData': '/api/data-users',
    'updateProfile': '/api/update-profile',
    // Cart endpoints
    'addToCart': '/api/cart/add',
    'getCart': '/api/cart',
    'updateCart': '/api/cart/update',
    'clearCart': '/api/cart/clear',
    'removeFromCart': '/api/cart/', // + productId
    'removeMultipleItems': '/api/cart/remove-multiple',
    // Wishlist endpoints
    'addToWishlist': '/api/wishlist/add',
    'getWishlist': '/api/wishlist',
    'removeFromWishlist': '/api/wishlist/', // + productId
    // Review endpoints
    'getProductReviews': '/api/products/', // + productId + /reviews
    'createReview': '/api/products/reviews',
    // Card endpoints
    'addCard': '/api/cards',
    'getCards': '/api/cards',
    'deleteCard': '/api/cards/', // + cardId
    // Search endpoint
    'searchProducts': '/api/products/search',
  };

  // Product API Endpoints
  static const Map<String, String> productEndpoints = {
    'getAllProducts': '/api/products',
    'getProductDetails': '/api/products/', // + id
    'getAllCategories': '/api/categories',
    'getProductsByCategory': '/api/categories/', // + categoryId + /products
  };

  // Camping Spots API Endpoints
  static const Map<String, String> campingEndpoints = {
    'getAllSpots': '/api/camping-spots',
    'getSpotDetails': '/api/camping-spots/', // + spotId
    'searchSpots': '/api/camping-spots/search',
    'getSpotReviews': '/api/camping-spots/', // + spotId + /reviews
    'createSpotReview': '/api/camping-spots/reviews',
  };

  // Map Configuration
  static const String osmTileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> osmSubdomains = ['a', 'b', 'c'];
  
  // OSRM Configuration
  static const String osrmUrl = 'https://router.project-osrm.org/route/v1';
  
  // Default Map Settings
  static const double defaultLatitude = 16.0544;  // Đà Nẵng
  static const double defaultLongitude = 108.2022;
  static const double defaultZoom = 13.0;

  // Upload Configuration
  static const int maxReviewImages = 5;
  static const String profileImageField = 'profileImage';
  static const String reviewImagesField = 'images';
  
  // App Settings
  static const String appName = 'CampGo';
  static const String version = '1.0.0';

  // Cache Settings
  static const int maxCacheAge = 7 * 24 * 60 * 60;  // 7 days in seconds
  static const int maxCacheSize = 10 * 1024 * 1024; // 10MB

  // Helper method để lấy full URL
  static String getFullUrl(String endpoint) {
    final url = baseUrl + endpoint;
    print('Generated URL: $url'); // Debug log
    return url;
  }

  // Helper method để lấy URL với parameter
  static String getUrlWithParam(String endpoint, String param) {
    final url = baseUrl + endpoint + param;
    print('Generated URL with param: $url'); // Debug log
    return url;
  }

  // Helper method để lấy URL với query parameters
  static String getUrlWithQuery(String endpoint, Map<String, String> queryParams) {
    final Uri uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
    final url = uri.toString();
    print('Generated URL with query: $url'); // Debug log
    return url;
  }
}
