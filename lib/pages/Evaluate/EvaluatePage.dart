import 'package:CampGo/pages/Evaluate/widgets/EvaluateFeedBackPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:CampGo/api/api.service.dart';
import 'package:intl/intl.dart';
import 'package:CampGo/services/share_service.dart';

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
      
      // Lấy thông tin người dùng hiện tại
      final userInfo = await ShareService.getUserInfo();
      if (userInfo == null) {
        print('User info is null');
        return false;
      }
      
      final userId = userInfo['userId'] as String?;
      if (userId == null) {
        print('User ID is null');
        return false;
      }
      
      print('Current user ID: $userId');
      
      final response = await APIService.getProductReviews(productId, forceRefresh: true);
      print('Review response: $response');
      
      if (response != null && response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is Map<String, dynamic> && data['reviews'] is List) {
          final List<dynamic> reviews = data['reviews'];
          print('Found ${reviews.length} reviews for product $productId');
          
          // Kiểm tra xem người dùng hiện tại đã đánh giá chưa
          final hasReviewed = reviews.any((review) {
            if (review is Map<String, dynamic>) {
              final reviewUserId = review['user_id'] as String?;
              print('Comparing review user ID: $reviewUserId with current user ID: $userId');
              return reviewUserId == userId;
            }
            return false;
          });
          
          print('User $userId has reviewed: $hasReviewed');
          return hasReviewed;
        }
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
            content: Text('There are no more products to review',
            textAlign: TextAlign.center,
            ),
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
                  ...products.map((product) => _buildProductItem(product, orderId: orderData['_id'])).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product, {required String orderId}) {
    // Xử lý lấy processedImageUrl ở đầu hàm
    String processedImageUrl = '';
    if (product['product']['images'] != null && product['product']['images'] is List && product['product']['images'].isNotEmpty) {
      var firstImage = product['product']['images'][0];
      if (firstImage is Map) {
        processedImageUrl = firstImage['url'] ?? '';
      } else {
        processedImageUrl = firstImage.toString();
      }
    }
    if (processedImageUrl.isEmpty) {
      processedImageUrl = product['product']['imageURL'] ?? '';
    }
    processedImageUrl = processedImageUrl.trim();
    print('EvaluatePage - Image URL: $processedImageUrl');

    // Tính toán giá sau khi giảm giá
    double price = (product['product']['price'] ?? 0).toDouble();
    int discount = (product['product']['discount'] ?? 0).toInt();
    double finalPrice = discount > 0 ? price * (1 - discount / 100) : price;
    int quantity = (product['quantity'] ?? 0).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (processedImageUrl.isEmpty || !processedImageUrl.startsWith('http'))
                ? Container(
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
                  )
                : Image.network(
                    processedImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('EvaluatePage - Image load error: $error');
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
                          'Price: \$${(finalPrice * quantity).toStringAsFixed(2)}',
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
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          );
                        }
                        
                        final bool isReviewed = snapshot.data ?? false;
                        print('Product ${product['product']['_id']} is reviewed: $isReviewed');
                        
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
                                      productImage: processedImageUrl,
                                      orderId: orderId,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  setState(() {
                                    _removeReviewedProduct(product['product']['_id']);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Product review success',
                                      textAlign: TextAlign.center,),
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
                                      content: Text('This product has been rated',
                                       textAlign: TextAlign.center,),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('An error occurred: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReviewed ? Colors.grey[400] : Colors.deepOrange,
                            disabledBackgroundColor: Colors.grey[400],
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isReviewed ? 'Reviewed' : 'Review',
                            style: const TextStyle(
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
