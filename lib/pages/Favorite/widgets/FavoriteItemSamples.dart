import 'package:CampGo/pages/Product/ProductPage.dart';
import 'package:flutter/material.dart';
import 'package:CampGo/services/api_service.dart';

class FavoriteItemSamples extends StatefulWidget {
  const FavoriteItemSamples({super.key});

  @override
  _FavoriteItemSamplesState createState() => _FavoriteItemSamplesState();
}

class _FavoriteItemSamplesState extends State<FavoriteItemSamples> {
  List<dynamic> wishlistItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      setState(() => isLoading = true);
      final response = await APIService.getWishlist();
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> wishlistProducts = response['data'];
        print('Raw wishlist data: $wishlistProducts');

        // Lấy thông tin chi tiết cho từng sản phẩm
        final List<Map<String, dynamic>> detailedProducts = [];
        for (var product in wishlistProducts) {
          try {
            final productId = product['_id'];
            final detailResponse = await APIService.getProductDetails(productId);
            
            if (detailResponse['success'] == true && detailResponse['data'] != null) {
              final productData = detailResponse['data'];
              print('Product detail data for $productId: $productData');

              // Xử lý URL hình ảnh
              String imageUrl = '';
              if (productData['images'] != null && productData['images'] is List && productData['images'].isNotEmpty) {
                var firstImage = productData['images'][0];
                if (firstImage is Map && firstImage.containsKey('url')) {
                  imageUrl = firstImage['url'].toString();
                }
              }
              print('Extracted image URL for $productId: $imageUrl');

              // Tính toán giá sau giảm giá
              final price = (productData['price'] ?? 0.0).toDouble();
              final discount = (productData['discount'] ?? 0).toDouble();
              final discountedPrice = price * (1 - discount / 100);

              detailedProducts.add({
                '_id': productId,
                'productName': productData['productName'],
                'price': price,
                'discount': discount,
                'discount_price': discountedPrice,
                'imageURL': imageUrl,
                'stockQuantity': productData['stockQuantity'],
                'description': productData['description'],
                'brand': productData['brand'],
                'sold': productData['sold'],
              });
            }
          } catch (e) {
            print('Error loading details for product ${product['_id']}: $e');
          }
        }

        setState(() {
          wishlistItems = detailedProducts;
          isLoading = false;
        });
        
        print('Loaded ${wishlistItems.length} detailed wishlist items');
        for (var item in wishlistItems) {
          print('Product ${item['_id']} - Image URL: ${item['imageURL']}');
        }
      } else {
        throw Exception(response['message'] ?? 'Không thể tải danh sách yêu thích');
      }
    } catch (e) {
      print("Error loading wishlist: $e");
      setState(() {
        isLoading = false;
        wishlistItems = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Không thể tải danh sách yêu thích')),
        );
      }
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    try {
      final result = await APIService.removeFromWishlist(productId);
      if (result['success'] == true) {
        setState(() {
          wishlistItems.removeWhere((item) => item['_id'] == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Đã xóa khỏi danh sách yêu thích')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Không thể xóa khỏi danh sách yêu thích')),
        );
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi xóa khỏi danh sách yêu thích')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (wishlistItems.isEmpty) {
      return const Center(
        child: Text(
          "Danh sách yêu thích trống",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Container(
      color: const Color(0xFFEDECF2),
      child: ListView.builder(
        itemCount: wishlistItems.length,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          final item = wishlistItems[index];
          final price = item['price']?.toDouble() ?? 0.0;
          final discountPrice = item['discount_price']?.toDouble() ?? price;
          final discount = item['discount']?.toDouble() ?? 0.0;
          final imageUrl = item['imageURL'] ?? '';
          
          print('Item ${index + 1} image URL: $imageUrl'); // Debug log
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hình ảnh sản phẩm
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey[400],
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Thông tin sản phẩm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['productName'] ?? 'Unknown product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2321),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '\$${discountPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            if (discount > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${discount.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Nút xóa và chuyển trang
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeFromWishlist(item['_id']),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Color(0xFF2B2321)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductPage(
                                productId: item['_id'],
                              ),
                            ),
                          ).then((_) => _loadWishlist());
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}