import 'package:flutter/material.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/pages/Product/widgets/ProductReviews.dart';

class ProductPage extends StatefulWidget {
  final String productId;

  const ProductPage({super.key, required this.productId});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? product;
  bool isLoading = true;
  int quantity = 1;
  bool isFavorite = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProduct();
    _checkFavoriteStatus();
  }

  Future<void> _loadProduct() async {
    try {
      print('Loading product with ID: ${widget.productId}');
      final response = await APIService.getProductDetails(widget.productId);
      final reviewResponse = await APIService.getProductReviews(widget.productId);
      
      if (response['success'] == true && response['data'] != null) {
        final productData = response['data'];
        double averageRating = 0.0;
        if (reviewResponse['success'] == true && reviewResponse['data'] != null) {
          averageRating = (reviewResponse['data']['summary']?['averageRating'] ?? 0.0).toDouble();
        }

        setState(() {
          product = {
            'id': productData['_id'],
            'name': productData['productName'],
            'description': productData['description'],
            'originalPrice': productData['originalPrice'] ?? productData['price'],
            'price': productData['price'],
            'discountedPrice': productData['price'],
            'discountPercentage': productData['discount'] ?? 0,
            'imageURL': productData['imageURL'] ?? 
              (productData['images']?.isNotEmpty == true ? 
                (productData['images'][0] is Map ? 
                  productData['images'][0]['url'] : 
                  productData['images'][0]) : 
                ''),
            'stockQuantity': productData['stockQuantity'],
            'soldCount': productData['sold'],
            'brand': productData['brand'],
            'categoryID': productData['categoryID'],
            'rating': averageRating,
            'totalReviews': reviewResponse['data']?['summary']?['totalReviews'] ?? 0,
          };
          isLoading = false;
        });
        print('Product loaded: ${product?['name']}');
        print('Image URL: ${product?['imageURL']}');
      } else {
        print('Error loading product: ${response['message']}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading product: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final response = await APIService.getWishlist();
      if (response['success'] == true && response['data'] != null) {
        final wishlistItems = response['data'] as List<dynamic>;
        setState(() {
          isFavorite = wishlistItems.any((item) => item['_id'] == widget.productId);
        });
        print('Favorite status: $isFavorite for product ${widget.productId}'); // Debug log
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> toggleFavorite() async {
    try {
      Map<String, dynamic>? response;
      if (isFavorite) {
        response = await APIService.removeFromWishlist(widget.productId);
        if (response != null && response['success'] == true) {
          setState(() => isFavorite = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites list',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Cannot remove from favorites list',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            )
          );
        }
      } else {
        response = await APIService.addToWishlist(widget.productId);
        if (response != null && response['success'] == true) {
          setState(() => isFavorite = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Added to favorites list',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Cannot add to favorites list',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            )
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void increaseQuantity() {
    if (product != null && product!['stockQuantity'] != null && 
        quantity < product!['stockQuantity']) {
      setState(() {
        quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot exceed stock quantity (${product?['stockQuantity'] ?? 0} products)',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void _addToCart() async {
    try {
      // Kiểm tra số lượng tồn kho
      if (product == null || product!['stockQuantity'] == null) {
        throw Exception('No product information available');
      }

      if (quantity > product!['stockQuantity']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantity exceeds stock quantity (${product!['stockQuantity']} products)',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Gọi API thêm vào giỏ hàng
      final response = await APIService.addToCart(widget.productId, quantity);
      print('Add to cart response: $response'); // Debug log
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart successfully!',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Chuyển đến trang giỏ hàng nếu người dùng muốn
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Column(
                  children: [
                    Text(
                      'Added to cart successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height:5),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 48, 67, 172).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 50,
                        color: Colors.green,
                      ),
                    )
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Do you want to view the cart?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
                contentPadding: EdgeInsets.fromLTRB(24, 10, 24, 0),
                actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Stay Shop',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 215, 159, 54),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'View cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushNamed(context, '/cart').then((_) {
                                if (mounted) {
                                  setState(() {});
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              );
            },
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Cannot add to cart');
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Product not found',
          textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          product!['name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.black,
              size: 30,
            ),
            onPressed: toggleFavorite,
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFEDECF2),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProductImage(screenWidth, screenHeight),
                  const SizedBox(height: 15),
                  _buildProductDetails(),
                  const SizedBox(height: 10),
                  _buildTabBar(),
                  _buildTabBarView(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProductImage(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth,
      height: screenHeight * 0.4,
      decoration: const BoxDecoration(
        color: Color(0xFFD9D9D9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.elliptical(250, 70),
          bottomRight: Radius.elliptical(250, 70),
        ),
      ),
      child: Hero(
        tag: 'product_image_${widget.productId}',
        child: Image.network(
          product!['imageURL'] ?? '',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey,
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    final discountPercentage = product!['discountPercentage'] ?? 0.0;
    final originalPrice = product!['originalPrice'] ?? 0.0;
    final discountedPrice = product!['price'] ?? originalPrice;
    final soldCount = product!['soldCount'] ?? 0;
    final stockQuantity = product!['stockQuantity'] ?? 0;
    final rating = product!['rating'] ?? 0.0;
    final totalReviews = product!['totalReviews'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product!['name'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2321),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.floor() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 23,
                  );
                }),
              ),
              const SizedBox(width: 4),
              Text(
                '($rating)',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2B2321),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                '$soldCount sold',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 91, 90, 90),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Phần điều chỉnh số lượng
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Minus button
              GestureDetector(
                onTap: decreaseQuantity,
                child: const Text(
                  '−',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Plus button
              GestureDetector(
                onTap: quantity < stockQuantity ? increaseQuantity : null,
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 24,
                    color: quantity < stockQuantity ? Colors.black54 : Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.blue,
      tabs: const [
        Tab(text: 'Description'),
        Tab(text: 'Reviews'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return SizedBox(
      height: 300,
      child: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông số sản phẩm
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDECF2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSpecItem('Brand:', product!['brand'] ?? 'N/A'),
                      _buildSpecItem('Quantity in stock:', '${product!['stockQuantity'] ?? 0} products'),
                    ],
                  ),
                ),
                // Mô tả sản phẩm
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDECF2), 
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product!['description'] ?? 'No description',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2B2321),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ProductReviews(productId: widget.productId),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF2B2321),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2B2321),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final discountPercentage = product!['discountPercentage'] ?? 0.0;
    final originalPrice = product!['originalPrice'] ?? 0.0;
    final discountedPrice = product!['price'] ?? originalPrice;
    final totalPrice = discountedPrice * quantity;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (discountPercentage > 0)
                Row(
                  children: [
                    Text(
                      '\$${(originalPrice * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '-$discountPercentage%',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: const Color.fromARGB(255, 215, 159, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            icon: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
            ),
            label: const Text(
              'Add To Cart',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
