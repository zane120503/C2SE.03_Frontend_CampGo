import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:CampGo/models/product.dart';
import 'package:CampGo/config/config.dart';
import 'package:CampGo/services/share_service.dart';

class ProductService {
  static final String baseUrl = Config.baseUrl;

  static Future<Product?> getProductById(String id) async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for getting product');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Get product by ID API response status: ${response.statusCode}');
      print('Get product by ID API response body: ${response.body}');

      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Product.fromJson(data['data']);
      }

      print('Failed to get product: ${data['message']}');
      return null;
    } catch (e) {
      print('Error getting product by ID: $e');
      return null;
    }
  }

  static Future<List<Product>> getAllProducts() async {
    try {
      String? token = await ShareService.getToken();
      if (token == null) {
        print('No token found for getting products');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Get all products API response status: ${response.statusCode}');
      print('Get all products API response body: ${response.body}');

      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((product) => Product.fromJson(product))
            .toList();
      }

      print('Failed to get products: ${data['message']}');
      return [];
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }
} 