import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:CampGo/models/Review.dart';
import 'package:CampGo/services/api_service.dart';

class ReviewData {
  final List<Review> reviews;
  final double averageRating;
  final int totalReviews;

  ReviewData({
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
  });
}

class ReviewService {
  Future<ReviewData> getProductReviews(String productId) async {
    try {
      print('Fetching reviews for product: $productId');
      final response = await APIService.getProductReviews(productId);
      print('API Response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        print('Review data: $data');
        
        // Kiểm tra cấu trúc của reviews trong response
        final reviewsList = data['reviews'] as List? ?? [];
        print('Reviews list: $reviewsList');
        
        final List<Review> reviews = reviewsList.map((review) {
          print('Processing review: $review');
          return Review.fromJson(review);
        }).toList();

        final averageRating = (data['summary']?['averageRating'] ?? 0.0).toDouble();
        final totalReviews = data['summary']?['totalReviews'] ?? 0;
        
        print('Processed ${reviews.length} reviews');
        print('Average rating: $averageRating');
        print('Total reviews: $totalReviews');

        return ReviewData(
          reviews: reviews,
          averageRating: averageRating,
          totalReviews: totalReviews,
        );
      } else {
        print('Failed to load reviews. Response: $response');
        throw Exception('Failed to load reviews');
      }
    } catch (e, stackTrace) {
      print('Error getting product reviews: $e');
      print('Stack trace: $stackTrace');
      return ReviewData(
        reviews: [],
        averageRating: 0,
        totalReviews: 0,
      );
    }
  }

  Future<bool> addReview({
    required String productId,
    required int rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      final response = await APIService.createProductReview(
        productId,
        rating.toDouble(),
        comment,
        images ?? [],
      );
      
      return response;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      // TODO: Implement khi có API endpoint
      return false;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    try {
      // TODO: Implement khi có API endpoint
      return false;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
} 