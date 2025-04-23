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
              String imageUrl = productData['imageURL'] ?? 
                (productData['images']?.isNotEmpty == true ? 
                  (productData['images'][0] is Map ? 
                    productData['images'][0]['url'] : 
                    productData['images'][0]) : 
                  '');

              // Tính toán giá sau giảm giá
              final price = (productData['price'] ?? 0.0).toDouble();
              final originalPrice = (productData['originalPrice'] ?? productData['price'] ?? 0.0).toDouble();
              final discount = (productData['discount'] ?? 0).toDouble();

              detailedProducts.add({
                '_id': productId,
                'productName': productData['productName'],
                'price': price,
                'originalPrice': originalPrice,
                'discount': discount,
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
        throw Exception(response['message'] ?? 'Unable to load favorites list');    
      }
    } catch (e) {
      print("Error loading wishlist: $e");
      setState(() {
        isLoading = false;
        wishlistItems = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Unable to load favorites list',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            ),
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
          SnackBar(content: Text(result['message'] ?? 'Removed from favorites list',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
          ),  
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Unable to remove from favorites list',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            ),
        );
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while removing from favorites list',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
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
          "Your wishlist is empty",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      children: wishlistItems.map((item) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Hình ảnh sản phẩm
                  Container(
                    width: 120,
                    height: 120,
                    child: ClipRRect(
                      child: item['imageURL'] != null && item['imageURL'].isNotEmpty
                          ? Image.network(
                              item['imageURL'],
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Thông tin sản phẩm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['productName'] ?? 'Unknown product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '\$${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            if (item['originalPrice'] != null && item['originalPrice'] > (item['price'] ?? 0)) ...[
                              const SizedBox(width: 8),
                              Text(
                                '\$${item['originalPrice']?.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 25,
                        ),
                        onPressed: () => removeFromWishlist(item['_id']),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 15),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black54,
                          size: 20,
                        ),
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
            if (item['originalPrice'] != null && item['originalPrice'] > (item['price'] ?? 0))
              Positioned(
                top: 0,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${((item['originalPrice']! - (item['price'] ?? 0)) / item['originalPrice']! * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}