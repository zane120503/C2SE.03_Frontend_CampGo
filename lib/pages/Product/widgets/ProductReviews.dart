import 'package:flutter/material.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/pages/Product/widgets/ProductReviewsItemSamples.dart';

class ProductReviews extends StatefulWidget {
  final String productId;

  const ProductReviews({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}
  
class _ProductReviewsState extends State<ProductReviews> {
  List<Map<String, dynamic>> reviews = [];
  double averageRating = 0.0;
  int totalReviews = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final response = await APIService.getProductReviews(widget.productId);
      print('Reviews response: $response'); // Debug log
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(response['data']['reviews'] ?? []);
          averageRating = (response['data']['summary']?['averageRating'] ?? 0.0).toDouble();
          totalReviews = response['data']['summary']?['totalReviews'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Thêm phương thức để cập nhật danh sách đánh giá
  void updateReviews(Map<String, dynamic> newReview) {
    setState(() {
      // Thêm review mới vào đầu danh sách
      reviews.insert(0, newReview);
      // Cập nhật tổng số review
      totalReviews++;
      // Cập nhật điểm trung bình
      final totalRating = reviews.fold<double>(0, (sum, review) => sum + (review['rating'] as num).toDouble());
      averageRating = totalRating / totalReviews;
    });
  }

  Widget _buildReviewSummary() {
    // Tính toán số lượng đánh giá cho mỗi mức sao
    final starCounts = List<int>.filled(5, 0);
    for (var review in reviews) {
      final rating = review['rating'] as int;
      if (rating >= 1 && rating <= 5) {
        starCounts[rating - 1]++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDECF2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.floor() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  Text(
                    '$totalReviews reviews',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 108, 108, 108),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hiển thị phân phối đánh giá
          ...List.generate(5, (index) {
            final starCount = starCounts[4 - index];
            final percentage = totalReviews > 0 ? (starCount / totalReviews * 100) : 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${5 - index} stars',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${starCount}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    if (reviews.isEmpty) {
      return const Center(
        child: Text(
          'No reviews yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Chỉ lấy 2 review mới nhất
    final latestReviews = reviews.take(2).toList();

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latestReviews.length,
          itemBuilder: (context, index) {
            final review = latestReviews[index];
            final String firstName = review['first_name'] ?? '';
            final String lastName = review['last_name'] ?? '';
            final String displayName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
            
            // Lấy thông tin ảnh profile từ user_image
            String? userImageUrl;
            if (review['user_image'] != null && review['user_image'] is Map) {
              userImageUrl = review['user_image']['url'] as String?;
            }
            
            final int rating = (review['rating'] ?? 0).toInt();
            final String comment = review['comment'] ?? '';
            final List<String> images = List<String>.from(review['images'] ?? []);
            final String createdAt = review['created_at'] ?? '';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: userImageUrl != null && userImageUrl.isNotEmpty 
                            ? NetworkImage(userImageUrl) as ImageProvider
                            : null,
                        child: (userImageUrl == null || userImageUrl.isEmpty)
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName.isNotEmpty ? displayName : 'Anonymous User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                if (createdAt.isNotEmpty)
                                  Text(
                                    _formatDate(createdAt),
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 108, 108, 108),
                                      fontSize: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    comment,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, imageIndex) {
                          final String imageUrl = images[imageIndex];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.startsWith('http')
                                  ? Image.network(
                                      imageUrl,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading image: $error');
                                        return Container(
                                          height: 100,
                                          width: 100,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/images/$imageUrl',
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading image: $error');
                                        return Container(
                                          height: 100,
                                          width: 100,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        // Nút "Xem tất cả"
        if (totalReviews > 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductReviewsItemSamples(productId: widget.productId),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All Reviews',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReviewSummary(),
          const SizedBox(height: 10),
          _buildReviewList(),
        ],
      ),
    );
  }
}
