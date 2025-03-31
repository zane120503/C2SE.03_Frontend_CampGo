import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:CampGo/model/wishlist_model.dart';

class MockDataService {
  // Load wishlist data from local JSON file
  Future<Wishlist?> getMockWishlist() async {
    try {
      final String response = await rootBundle.loadString('assets/data/Wishlist.json');
      final data = json.decode(response);
      return Wishlist.fromJson(data);
    } catch (e) {
      print("Error loading wishlist data: $e");
      return null;
    }
  }
  
  // Load reviews data from local JSON file
  Future<List<Review>> getMockReviews() async {
    try {
      final String response = await rootBundle.loadString('assets/data/Review.json');
      final data = json.decode(response);
      final List<dynamic> reviewsJson = data['reviews'];
      return reviewsJson.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print("Error loading reviews: $e");
      return [];
    }
  }
  
  // Get a specific review by product ID
  Future<Review?> getReviewForProduct(String productId) async {
    final reviews = await getMockReviews();
    try {
      return reviews.firstWhere((review) => review.id == productId);
    } catch (e) {
      print("No review found for product ID: $productId");
      return null;
    }
  }
  
  // Delete wishlist item (mock implementation)
  Future<bool> deleteWishlistItem(String productId) async {
    // This is a mock implementation that always returns success
    // In a real app, you would update the local mock data or call an API
    return true;
  }
}