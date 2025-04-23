import 'package:flutter/material.dart';
import 'package:CampGo/models/Review.dart';
import 'package:CampGo/services/review_service.dart';

class ProductReviewsItemSamples extends StatefulWidget {
  final String productId;

  const ProductReviewsItemSamples({super.key, required this.productId});

  @override
  State<ProductReviewsItemSamples> createState() => _ProductReviewsItemSamplesState();
}

class _ProductReviewsItemSamplesState extends State<ProductReviewsItemSamples> {
  final ReviewService _reviewService = ReviewService();
  bool isLoading = true;
  List<Review> reviews = [];
  double averageRating = 0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviewData = await _reviewService.getProductReviews(widget.productId);
      setState(() {
        reviews = reviewData.reviews;
        averageRating = reviewData.averageRating;
        totalReviews = reviewData.totalReviews;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Reviews',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$totalReviews reviews • ${averageRating.toStringAsFixed(1)} stars',
              style: const TextStyle(
                color: Color.fromARGB(255, 108, 108, 108),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reviews.isEmpty
              ? const Center(
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: review.userImage != null && review.userImage!.isNotEmpty
                                      ? NetworkImage(review.userImage!) as ImageProvider
                                      : null,
                                  child: (review.userImage == null || review.userImage!.isEmpty)
                                      ? Text(
                                          review.displayName.isNotEmpty ? review.displayName[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          ...List.generate(5, (index) {
                                            return Icon(
                                              index < review.rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(review.createdAt),
                                            style: TextStyle(
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
                              review.comment,
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (review.images.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: review.images.length,
                                  itemBuilder: (context, imageIndex) {
                                    final String imageUrl = review.images[imageIndex];
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
                                                    color: Colors.grey[300],
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
                                                    color: Colors.grey[300],
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
                      ),
                    );
                  },
                ),
    );
  }
}
