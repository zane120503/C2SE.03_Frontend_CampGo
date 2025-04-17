import 'package:CampGo/pages/Evaluate/widgets/EvaluateFeedBackPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:CampGo/api/api.service.dart';
import 'package:intl/intl.dart';

class EvaluatePage extends StatefulWidget {
  const EvaluatePage({super.key});

  @override
  State<EvaluatePage> createState() => _EvaluateState();
}

class _EvaluateState extends State<EvaluatePage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveredOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload dữ liệu khi quay lại trang
    _loadDeliveredOrders();
  }

  Future<bool> _checkIfProductReviewed(String productId) async {
    try {
      print('Checking review status for product: $productId');
      
      final response = await APIService.getProductReviews(productId, forceRefresh: true);
      print('Review response: $response'); // Debug log
      
      if (response != null && response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is Map<String, dynamic> && data['reviews'] is List) {
          final List<dynamic> reviews = data['reviews'];
          print('Found ${reviews.length} reviews for product $productId');
          
          for (var review in reviews) {
            if (review is Map<String, dynamic>) {
              if (review['is_current_user'] == true) {
                print('Found review by current user for product $productId');
                return true;
              }
            }
          }
          print('No review found by current user for product $productId');
        } else {
          print('Invalid reviews data structure for product $productId: $data');
        }
      } else {
        print('Failed to get reviews for product $productId. Response: $response');
      }
      return false;
    } catch (e) {
      print('Error checking review status: $e');
      return false;
    }
  }

  Future<void> _loadDeliveredOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Clear cache trước khi lấy dữ liệu mới
      APIService.clearCache();
      
      final response = await APIService.getOrders();
      if (response != null && response['success'] == true) {
        final List<dynamic> ordersData = response['data'] ?? [];
        
        // Lọc các đơn hàng đã giao và đã thanh toán
        final deliveredOrders = ordersData
            .where((order) => 
              order['delivery_status'] == 'Delivered' && 
              order['payment_status'] == 'Completed')
            .map((e) => e as Map<String, dynamic>)
            .toList();

        setState(() {
          _orders = deliveredOrders;
          _isLoading = false;
        });
      } else {
        print('Failed to get orders: $response');
        setState(() {
          _isLoading = false;
          _orders = [];
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
        _orders = [];
      });
    }
  }

  // Hàm xóa sản phẩm khỏi danh sách sau khi đã review
  void _removeReviewedProduct(String productId) {
    print('Removing reviewed product: $productId'); // Debug log
    print('Current orders count before removal: ${_orders.length}'); // Debug log
    
    setState(() {
      // Tạo danh sách orders mới
      List<Map<String, dynamic>> updatedOrders = [];
      // Cập nhật danh sách orders
      _orders = updatedOrders;
      print('Final orders count after removal: ${_orders.length}'); // Debug log
      
      // Nếu không còn sản phẩm nào cần review
      if (_orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không còn sản phẩm nào cần đánh giá'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: Padding(
            padding: const EdgeInsets.only(top: 0),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                size: 30,
                color: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Container(
            child: const Text(
              'Evaluate',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Text(
                    'No orders to evaluate',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDECF2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // Refresh lại toàn bộ danh sách khi người dùng kéo xuống
                        setState(() {
                          _loadDeliveredOrders();
                        });
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_orders[index]);
                        },
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> orderData) {
    List<dynamic> products = orderData['products'] ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order ID: ${orderData['_id']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 255, 0, 0),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Delivered',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Colors.black,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  const SizedBox(height: 8),
                  ...products.map((product) => _buildProductItem(product)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product['product']['imageURL'] ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 30,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product']['productName'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity: ${product['quantity']}',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 76, 76, 76),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Price: \$${product['amount']}',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 76, 76, 76),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    FutureBuilder<bool>(
                      future: _checkIfProductReviewed(product['product']['_id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        
                        final bool isReviewed = snapshot.data ?? false;
                        
                        return ElevatedButton(
                          onPressed: isReviewed ? null : () async {
                            if (!isReviewed) {
                              try {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EvaluateFeedBackPage(
                                      productId: product['product']['_id'],
                                      productName: product['product']['productName'],
                                      productImage: product['product']['imageURL'],
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  setState(() {
                                    _removeReviewedProduct(product['product']['_id']);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đánh giá sản phẩm thành công'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error during review: $e');
                                if (e.toString().contains('already reviewed')) {
                                  setState(() {
                                    _removeReviewedProduct(product['product']['_id']);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sản phẩm này đã được đánh giá'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Có lỗi xảy ra: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReviewed ? Colors.grey : Colors.deepOrange,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isReviewed ? 'Đã review' : 'Review',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReturnPage extends StatelessWidget {
  const ReturnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Page'),
      ),
      body: Center(
        child: const Text('This is the return page!'),
      ),
    );
  }
}
