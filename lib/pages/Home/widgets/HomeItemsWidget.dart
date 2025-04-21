import 'package:flutter/material.dart';
import 'package:CampGo/services/api_service.dart' as api;
import 'package:CampGo/pages/Product/ProductPage.dart';

class HomeItemsWidget extends StatefulWidget {
  final String selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  
  const HomeItemsWidget({
    Key? key, 
    required this.selectedCategory,
    this.minPrice,
    this.maxPrice,
  }) : super(key: key);

  @override
  State<HomeItemsWidget> createState() => _HomeItemsWidgetState();
}

class _HomeItemsWidgetState extends State<HomeItemsWidget> {
  List<dynamic> products = [];
  Set<String> favoriteProducts = {};
  bool isLoading = true;
  String? selectedCategory;
  double? minPrice;
  double? maxPrice;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.selectedCategory;
    minPrice = widget.minPrice;
    maxPrice = widget.maxPrice;
    loadProducts();
    loadFavorites();
  }

  @override
  void didUpdateWidget(HomeItemsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory ||
        oldWidget.minPrice != widget.minPrice ||
        oldWidget.maxPrice != widget.maxPrice) {
      setState(() {
        selectedCategory = widget.selectedCategory;
        minPrice = widget.minPrice;
        maxPrice = widget.maxPrice;
      });
      loadProducts();
    }
  }

  Future<void> loadProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await api.APIService.getAllProducts();
      print('API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        List<dynamic> allProducts = response['data']['products'] as List<dynamic>;
        
        products = allProducts.where((product) {
          // Kiểm tra category
          final productCategoryId = product['categoryID'] is Map 
              ? product['categoryID']['_id']?.toString()
              : product['categoryID']?.toString();
              
          bool matchesCategory = selectedCategory == null || 
              selectedCategory!.isEmpty || 
              selectedCategory == 'all' ||
              productCategoryId == selectedCategory;

          // Tính giá cuối cùng của sản phẩm
          double originalPrice = double.tryParse(product['originalPrice']?.toString() ?? '0') ?? 0.0;
          double discount = (product['discount'] ?? 0).toDouble();
          double finalPrice = discount > 0 
              ? originalPrice * (1 - discount / 100) 
              : originalPrice;
          
          print('Product: ${product['name']}');
          print('Category ID: $productCategoryId');
          print('Selected Category: $selectedCategory');
          print('Matches Category: $matchesCategory');
          print('Final Price: $finalPrice');
          print('-------------------');

          // Kiểm tra khoảng giá
          bool matchesPrice = true;
          if (minPrice != null || maxPrice != null) {
            if (minPrice != null) {
              matchesPrice = matchesPrice && finalPrice >= minPrice!;
            }
            if (maxPrice != null) {
              matchesPrice = matchesPrice && finalPrice <= maxPrice!;
            }
          }

          return matchesCategory && matchesPrice;
        }).toList();

        print('Filtered Products Count: ${products.length}');
        print('Applied Filters - Category: $selectedCategory, Min Price: $minPrice, Max Price: $maxPrice');
      } else {
        products = [];
      }

      setState(() {
        isLoading = false;
      });

    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        products = [];
        isLoading = false;
      });
    }
  }

  Future<void> loadFavorites() async {
    try {
      final response = await api.APIService.getWishlist();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          favoriteProducts = Set<String>.from(
            (response['data'] as List<dynamic>)
                .map((item) => item['_id'].toString())
          );
        });
        print('Loaded favorites: $favoriteProducts'); // Debug log
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  void toggleFavorite(String productId) async {
    try {
      if (favoriteProducts.contains(productId)) {
        // Xóa khỏi danh sách yêu thích
        final result = await api.APIService.removeFromWishlist(productId);
        if (result['success']) {
          setState(() {
            favoriteProducts.remove(productId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Đã xóa khỏi danh sách yêu thích')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Không thể xóa khỏi danh sách yêu thích')),
          );
        }
      } else {
        // Thêm vào danh sách yêu thích
        final result = await api.APIService.addToWishlist(productId);
        if (result['success']) {
          setState(() {
            favoriteProducts.add(productId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Đã thêm vào danh sách yêu thích')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Không thể thêm vào danh sách yêu thích')),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi cập nhật danh sách yêu thích')),
      );
    }
  }

  Future<void> _navigateToProductPage(String productId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPage(productId: productId),
      ),
    );
    loadFavorites();
  }

  void applyFilters(String? category, double? min, double? max) {
    print('Applying filters in HomeItemsWidget:');
    print('Category: $category');
    print('Min Price: $min');
    print('Max Price: $max');

    setState(() {
      selectedCategory = category;
      minPrice = min;
      maxPrice = max;
    });

    loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return Center(child: Text('Không tìm thấy sản phẩm nào'));
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      physics: BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.all(15),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final productId = product['_id']?.toString() ?? '';
        final isFavorite = favoriteProducts.contains(productId);
        
        final originalPrice = double.tryParse(product['originalPrice']?.toString() ?? '0') ?? 0;
        final discountedPrice = double.tryParse(product['discountedPrice']?.toString() ?? '0') ?? 0;
        final discount = product['discount']?.toDouble() ?? 0;
        
        final name = product['name'] ?? '';
        final soldCount = product['soldCount']?.toString() ?? '0';
        final rating = product['rating']?.toString() ?? '5.0';

        final images = product['images'] as List<dynamic>?;
        final imageUrl = (images != null && images.isNotEmpty) 
            ? images[0].toString()
            : product['imageURL']?.toString() ?? '';

        print('Product $productId - Name: $name - Image URL: $imageUrl');

        return GestureDetector(
          onTap: () => _navigateToProductPage(productId),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                            )
                          : _buildPlaceholder(),
                    ),
                    if (discount > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "-$discount%",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 20,
                          ),
                          onPressed: () => toggleFavorite(productId),
                          constraints: BoxConstraints.tightFor(width: 30, height: 30),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            if (originalPrice > 0) ...[
                              Text(
                                "\$${originalPrice.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 4),
                            ],
                            Text(
                              "\$${discountedPrice.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Row(
                          children: [
                            Text(
                              "$soldCount đã bán",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            Text(
                              " $rating",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 140,
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildProductImage(dynamic product) {
    final List<dynamic> images = product['images'] ?? [];
    String imageUrl = '';
    
    if (images.isNotEmpty) {
      // Kiểm tra nếu images[0] là một Map
      if (images[0] is Map) {
        imageUrl = images[0]['url'] ?? '';
      } else {
        // Nếu images[0] là một String
        imageUrl = images[0].toString();
      }
    }

    // Nếu không có imageUrl từ images, thử lấy từ imageURL
    if (imageUrl.isEmpty) {
      imageUrl = product['imageURL']?.toString() ?? '';
    }

    print('Building product image - Product ID: ${product['_id']}');
    print('Image URL: $imageUrl');
    print('Images array: $images');

    if (imageUrl.isEmpty) {
      return Container(
        height: 140,
        color: Colors.grey[100],
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 40,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      child: Image.network(
        imageUrl,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(
            height: 140,
            color: Colors.grey[100],
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 140,
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}