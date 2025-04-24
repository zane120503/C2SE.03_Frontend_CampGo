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
  Map<String, double> productRatings = {};
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

  Future<void> loadProductRatings() async {
    try {
      for (var product in products) {
        final productId = product['_id']?.toString() ?? '';
        final response = await api.APIService.getProductReviews(productId);
        
        if (response['success'] == true && response['data'] != null) {
          final averageRating = (response['data']['summary']?['averageRating'] ?? 0.0).toDouble();
          setState(() {
            productRatings[productId] = averageRating;
          });
        }
      }
    } catch (e) {
      print('Error loading product ratings: $e');
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

          // Lấy giá gốc và giá sau giảm
          final originalPrice = double.tryParse(product['originalPrice']?.toString() ?? '0') ?? double.tryParse(product['price']?.toString() ?? '0') ?? 0;
          final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
          final discount = product['discount']?.toDouble() ?? 0;
          final discountedPrice = originalPrice * (1 - discount / 100);
          
          // Kiểm tra khoảng giá
          bool matchesPrice = true;
          if (minPrice != null || maxPrice != null) {
            if (minPrice != null) {
              matchesPrice = matchesPrice && discountedPrice >= minPrice!;
            }
            if (maxPrice != null) {
              matchesPrice = matchesPrice && discountedPrice <= maxPrice!;
            }
          }

          return matchesCategory && matchesPrice;
        }).toList();

        // Load ratings sau khi có danh sách sản phẩm
        await loadProductRatings();

        setState(() {
          isLoading = false;
        });

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
            SnackBar(content: Text(result['message'] ?? 'Removed from favorites',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Cannot remove from favorites',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            ),
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
            SnackBar(content: Text(result['message'] ?? 'Added to favorites',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Cannot add to favorites',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while updating the favorites list',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
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
      return Center(child: Text('No products found'));
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
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
        
        // Lấy giá gốc và giá sau giảm
        final originalPrice = double.tryParse(product['originalPrice']?.toString() ?? '0') ?? double.tryParse(product['price']?.toString() ?? '0') ?? 0;
        final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
        final discount = product['discount']?.toDouble() ?? 0;
        final discountedPrice = originalPrice * (1 - discount / 100);
        
        // Lấy rating từ productRatings map
        final rating = productRatings[productId] ?? 0.0;
        
        // Debug log
        print('Product: ${product['name']}');
        print('Original Price: $originalPrice');
        print('Price: $price');
        print('Discount: $discount%');
        print('Discounted Price: $discountedPrice');
        
        final name = product['name'] ?? '';
        final soldCount = product['soldCount']?.toString() ?? '0';

        final images = product['images'] as List<dynamic>?;
        final imageUrl = (images != null && images.isNotEmpty) 
            ? images[0].toString()
            : product['imageURL']?.toString() ?? '';

        return GestureDetector(
          onTap: () => _navigateToProductPage(productId),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 3),
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
                              height: 150,
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
                        top: 10,
                        left: 10,
                        right: 45,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "-${discount.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      right: 3,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : const Color.fromARGB(255, 160, 69, 69),
                          size: 30,
                        ),
                        onPressed: () => toggleFavorite(productId),
                        constraints: BoxConstraints.tightFor(width: 32, height: 32),
                        padding: EdgeInsets.zero,
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
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            if (discount > 0) ...[
                              Text(
                                '\$${originalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                "\$${discountedPrice.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ] else
                              Text(
                                "\$${originalPrice.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$soldCount sold",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                Text(
                                  " ${rating.toStringAsFixed(1)}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
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
      height: 150,
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