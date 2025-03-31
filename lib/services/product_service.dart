import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:CampGo/model/product_model.dart';

class ProductService {
  static Future<Product?> getProductById(String id) async {
    try {
      final String response = await rootBundle.loadString('assets/data/Product.json');
      final data = await json.decode(response);
      
      if (data['products'] != null) {
        final products = (data['products'] as List);
        final product = products.firstWhere(
          (product) => product['id'].toString() == id,
          orElse: () => null,
        );
        
        if (product != null) {
          return Product.fromJson(product);
        }
      }
      return null;
    } catch (e) {
      print('Lỗi khi tải sản phẩm: $e');
      return null;
    }
  }

  static Future<List<Product>> getAllProducts() async {
    try {
      final String response = await rootBundle.loadString('assets/data/Product.json');
      final data = await json.decode(response);
      
      if (data['products'] != null) {
        return (data['products'] as List)
            .map((product) => Product.fromJson(product))
            .toList();
      }
      return [];
    } catch (e) {
      print('Lỗi khi tải danh sách sản phẩm: $e');
      return [];
    }
  }
} 