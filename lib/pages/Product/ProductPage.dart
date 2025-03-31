import 'package:flutter/material.dart';
import 'package:CampGo/model/product_model.dart';
import 'package:CampGo/services/product_service.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ProductPage extends StatefulWidget {
  final String productId;

  const ProductPage({super.key, required this.productId});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  Product? product;
  bool isLoading = true;
  int quantity = 1;
  bool isFavorite = false;
  Color? selectedColor;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      print('Loading product with ID: ${widget.productId}');
      final loadedProduct = await ProductService.getProductById(widget.productId);
      setState(() {
        product = loadedProduct;
        isLoading = false;
      });
      print('Product loaded: ${product?.name}');
    } catch (e) {
      print('Error loading product: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void toggleFavorite() async {
    if (!await AuthService.isLoggedIn()) {
      AuthService.showLoginDialog(context);
      return;
    }
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  void _addToCart() async {
    if (!await AuthService.isLoggedIn()) {
      AuthService.showLoginDialog(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm vào giỏ hàng!'),
        backgroundColor: Colors.green,
      ),
    );
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
          child: Text('Không tìm thấy sản phẩm'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          product!.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hình ảnh sản phẩm
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: Image.asset(
                      product!.imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên sản phẩm
                        Text(
                          product!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Giá và giảm giá
                        Row(
                          children: [
                            Text(
                              '${product!.price}đ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: product!.discountPercentage > 0 ? Colors.grey : Colors.black,
                                decoration: product!.discountPercentage > 0 ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (product!.discountPercentage > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${product!.price * (1 - product!.discountPercentage / 100)}đ',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Đánh giá và số lượng đã bán
                        Row(
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < product!.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text('(${product!.rating})'),
                            const SizedBox(width: 16),
                            Text('Đã bán: ${product!.soldCount}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Số lượng
                Row(
                  children: [
                    IconButton(
                      onPressed: decreaseQuantity,
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontSize: 18),
                    ),
                    IconButton(
                      onPressed: increaseQuantity,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const Spacer(),
                // Nút thêm vào giỏ hàng
                ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Thêm vào giỏ hàng',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
