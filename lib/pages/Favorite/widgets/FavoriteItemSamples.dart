import 'package:CampGo/pages/Product/ProductPage.dart';
import 'package:CampGo/services/MockDataService.dart';
import 'package:flutter/material.dart';
import 'package:CampGo/model/wishlist_model.dart';

class FavoriteItemSamples extends StatefulWidget {
  const FavoriteItemSamples({super.key});

  @override
  _FavoriteItemSamplesState createState() => _FavoriteItemSamplesState();
}

class _FavoriteItemSamplesState extends State<FavoriteItemSamples> {
  Wishlist? wishlist;
  List<Review>? reviews; // Thêm biến để lưu danh sách review
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      // Sử dụng MockDataService thay vì DataService
      final mockService = MockDataService();
      
      // Tải wishlist từ file JSON
      Wishlist? loadedWishlist = await mockService.getMockWishlist();
      
      // Tải reviews từ file JSON
      List<Review> loadedReviews = await mockService.getMockReviews();
      
      setState(() {
        wishlist = loadedWishlist;
        reviews = loadedReviews;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading wishlist data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    try {
      // Giả lập việc xóa sản phẩm khỏi wishlist
      setState(() {
        wishlist?.product.removeWhere((item) => item.product?.id == productId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from wishlist')),
      );
    } catch (e) {
      print("Error removing from wishlist: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error removing from wishlist')),
      );
    }
  }

  // Tìm review cho sản phẩm cụ thể
  Review? _getReviewForProduct(String productId) {
    if (reviews == null) return null;
    try {
      return reviews!.firstWhere((review) => review.id == productId);
    } catch (e) {
      print("No review found for product ID: $productId");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (wishlist == null || wishlist!.product.isEmpty) {
      return const Center(child: Text("Your wishlist is empty"));
    } else {
      return Column(
        children: wishlist!.product.map((item) {
          // Lấy review cho sản phẩm này
          Review? review = _getReviewForProduct(item.product?.id ?? "");
          
          return Container(
            height: 110,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 70,
                  width: 70,
                  child: item.product!.images != null &&
                          item.product!.images!.isNotEmpty
                      ? Image.network(item.product!.images![0])
                      : const Placeholder(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            item.product?.name ?? 'Unknown product',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B2321),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            "\$${item.product?.price?.toStringAsFixed(0) ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B2321),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        _removeFromWishlist(item.product?.id ?? "");
                      },
                      child: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 25),
                    InkWell(
                      onTap: () {
                        if (item.product != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductPage(
                                productId: item.product!.id ?? '',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF2B2321),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
  }
}