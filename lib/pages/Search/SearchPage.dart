import 'package:flutter/material.dart';
import 'dart:async';
import 'package:CampGo/pages/Product/ProductPage.dart';
import 'package:CampGo/services/api_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<dynamic> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;

  void _performSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);

      try {
        final response = await APIService.searchProducts(query: query.trim());
        print('Search query: ${query.trim()}');
        print('Search response: $response');

        setState(() {
          if (response['success'] == true && 
              response['data'] != null && 
              response['data']['products'] != null) {
            // Lọc sản phẩm theo từ khóa tìm kiếm
            final List<dynamic> allProducts = response['data']['products'];
            _searchResults = allProducts.where((product) {
              final String productName = (product['productName'] ?? '').toLowerCase();
              final String searchQuery = query.toLowerCase();
              return productName.contains(searchQuery);
            }).toList();
            
            print('Filtered results count: ${_searchResults.length}');
          } else {
            _searchResults = [];
          }
          _isLoading = false;
        });
      } catch (e) {
        print('Error searching products: $e');
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching products: $e',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty ? 'Enter search keyword' : 'No products found',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        final double originalPrice = (product['price'] ?? 0).toDouble();
        final double discount = (product['discount'] ?? 0).toDouble();
        final double discountedPrice = originalPrice * (1 - discount / 100);
        
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductPage(
                  productId: product['_id'] ?? '',
                ),
              ),
            );
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(4),
                        ),
                      ),
                      child: _buildProductImage(product),
                    ),
                    if (discount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            '-${discount.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['productName'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (discount > 0) ...[
                          Text(
                            '\$${originalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          '\$${discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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

  Widget _buildProductImage(dynamic product) {
    String imageUrl = '';
    
    // Kiểm tra và lấy URL hình ảnh từ mảng images trước
    if (product['images'] != null && product['images'] is List && product['images'].isNotEmpty) {
      var firstImage = product['images'][0];
      if (firstImage is Map) {
        imageUrl = firstImage['url'] ?? '';
      } else {
        imageUrl = firstImage.toString();
      }
    }
    
    // Nếu không có trong mảng images, thử lấy từ imageURL
    if (imageUrl.isEmpty) {
      imageUrl = product['imageURL'] ?? '';
    }

    // Nếu imageUrl là đường dẫn tương đối, thêm baseUrl
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = '${APIService.baseUrl}$imageUrl';
    }

    print('Product: ${product['productName']}');
    print('Image URL: $imageUrl');

    if (imageUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey,
            ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
}
