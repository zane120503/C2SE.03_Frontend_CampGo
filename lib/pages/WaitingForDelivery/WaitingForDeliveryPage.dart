import 'package:CampGo/pages/Evaluate/EvaluatePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:CampGo/api/api.service.dart';

class WaitingForDeliveryPage extends StatefulWidget {
  const WaitingForDeliveryPage({super.key});

  @override
  State<WaitingForDeliveryPage> createState() => _WaitingForDeliveryState();
}

class _WaitingForDeliveryState extends State<WaitingForDeliveryPage> {
  final Map<String, bool> _expandedOrders = {};
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('Loading orders for delivery...');
      final response = await APIService.getOrders();
      print('Orders API response: $response');
      
      if (response != null && response['success'] == true) {
        final List<dynamic> ordersData = response['data'] ?? [];
        print('Number of orders received: ${ordersData.length}');
        
        final filteredOrders = ordersData
            .where((order) {
              print('Processing order: ${order['_id']}');
              print('Order status - Waiting Confirmation: ${order['waiting_confirmation']}');
              print('Order status - Delivery Status: ${order['delivery_status']}');
              
              // Chỉ lấy các đơn hàng đã được xác nhận và đang giao
              return order['waiting_confirmation'] == true && 
                     order['delivery_status'] == 'Shipping';
            })
            .map((e) => e as Map<String, dynamic>)
            .toList();
            
        print('Number of filtered orders for delivery: ${filteredOrders.length}');
        
        setState(() {
          _orders = filteredOrders;
        });
      } else {
        print('Failed to load orders: ${response?['message']}');
        setState(() {
          _orders = [];
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _orders = [];
      });
    } finally { 
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  double _calculateTotalAmount(Map<String, dynamic> orderData) {
    double total = 0;
    List<dynamic> products = orderData['products'] ?? [];
    
    for (var product in products) {
      double price = (product['product']['price'] ?? 0).toDouble();
      int discount = (product['product']['discount'] ?? 0).toInt();
      int quantity = (product['quantity'] ?? 0).toInt();
      
      // Tính giá sau khi giảm giá
      if (discount > 0) {
        price = price * (1 - discount / 100);
      }
      
      total += price * quantity;
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              'Waiting For Delivery',
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
      body: Container(
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders are waiting for delivery',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 5),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderSection(_orders[index]);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildOrderSection(Map<String, dynamic> orderData) {
    bool isExpanded = _expandedOrders[orderData['_id']] ?? false;
    List<dynamic> products = orderData['products'] ?? [];
    
    // Tính toán thời gian để enable button
    DateTime updatedDate = DateTime.parse(orderData['updatedAt']);
    DateTime estimatedDeliveryDate = updatedDate.add(const Duration(days: 3));
    DateTime now = DateTime.now();
    
    // Kiểm tra điều kiện để có thể nhận hàng
    bool canReceive = orderData['waiting_confirmation'] == true && 
                     orderData['delivery_status'] == 'Shipping' &&
                     now.isAfter(estimatedDeliveryDate);

    String formattedOrderDate = updatedDate.toString().substring(0, 10);
    String formattedEstimatedDate = estimatedDeliveryDate.toString().substring(0, 10);

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
              padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0, top: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(                  
                          children: [
                            Text(
                              'Order ID: ',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 255, 0, 0),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${orderData['_id']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 255, 0, 0),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.deepOrange),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_shipping,
                              color: Colors.deepOrange,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Shipping',
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Payment Method: ',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${orderData['payment_method']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Payment Status: ',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${orderData['payment_status']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Order Date: ',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        formattedOrderDate,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Estimated Delivery Date: ',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        formattedEstimatedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProductImages(products),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, thickness: 0.5, color: Colors.grey),
              ...products.map((product) => _buildExpandedProductItem(product)).toList(),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: ElevatedButton.icon(
                      onPressed: canReceive ? () async {
                        try {
                          final result = await APIService.confirmDelivery(orderData['_id']);
                          if (result['success']) {
                            setState(() {
                              _orders.removeWhere((order) => order['_id'] == orderData['_id']);
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: Colors.green,
                              ),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EvaluatePage(),
                              ),
                            );
                          } else {
                            throw Exception(result['message']);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } : null,
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Received',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canReceive ? Colors.green : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _expandedOrders[orderData['_id']] = !isExpanded;
                      });
                    },
                    child: Text(
                      isExpanded ? 'See Less' : 'See More',
                      style: TextStyle(
                        color: Colors.deepOrange[400],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedProductItem(Map<String, dynamic> product) {
    // Tính toán giá sau khi giảm giá
    double price = (product['product']['price'] ?? 0).toDouble();
    int discount = (product['product']['discount'] ?? 0).toInt();
    double discountedPrice = discount > 0 ? price * (1 - discount / 100) : price;
    int quantity = (product['quantity'] ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(  
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Builder(
                  builder: (context) {
                    String processedImageUrl = '';
                    
                    // Kiểm tra và lấy URL từ mảng images trước
                    if (product['product']['images'] != null && 
                        product['product']['images'] is List && 
                        product['product']['images'].isNotEmpty) {
                      var firstImage = product['product']['images'][0];
                      if (firstImage is Map) {
                        processedImageUrl = firstImage['url'] ?? '';
                      } else {
                        processedImageUrl = firstImage.toString();
                      }
                    }
                    
                    // Nếu không có trong mảng images, thử lấy từ imageURL
                    if (processedImageUrl.isEmpty) {
                      processedImageUrl = product['product']['imageURL'] ?? '';
                    }
                    
                    processedImageUrl = processedImageUrl.trim();
                    print('WaitingForDeliveryPage - Image URL: $processedImageUrl');
                    
                    if (processedImageUrl.isEmpty || !processedImageUrl.startsWith('http')) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    }
                    
                    return Image.network(
                      processedImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('WaitingForDeliveryPage - Image load error: $error');
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
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
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Quantity: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${product['quantity']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.deepOrange),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Shipping',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (discount > 0) ...[
                    Row(
                      children: [
                        Text(
                          '\$${(discountedPrice * quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$discount%',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${(price * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ] else
                    Text(
                      '\$${(price * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImages(List<dynamic> products) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: products.take(3).map<Widget>((product) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Builder(
                builder: (context) {
                  String processedImageUrl = '';
                  
                  // Kiểm tra và lấy URL từ mảng images trước
                  if (product['product']['images'] != null && 
                      product['product']['images'] is List && 
                      product['product']['images'].isNotEmpty) {
                    var firstImage = product['product']['images'][0];
                    if (firstImage is Map) {
                      processedImageUrl = firstImage['url'] ?? '';
                    } else {
                      processedImageUrl = firstImage.toString();
                    }
                  }
                  
                  // Nếu không có trong mảng images, thử lấy từ imageURL
                  if (processedImageUrl.isEmpty) {
                    processedImageUrl = product['product']['imageURL'] ?? '';
                  }
                  
                  processedImageUrl = processedImageUrl.trim();
                  print('WaitingForDeliveryPage - Image URL: $processedImageUrl');
                  
                  if (processedImageUrl.isEmpty || !processedImageUrl.startsWith('http')) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  }
                  
                  return Image.network(
                    processedImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('WaitingForDeliveryPage - Image load error: $error');
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
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
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductContent({
    required String imageUrl,
    required String productName,
    required String productDetail,
    required String totalAmountLabel,
    required String totalAmount,
    required List<String> tags,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productDetail,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  totalAmountLabel,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Text(
                totalAmount,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tags.map((tag) => _buildTag(tag)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepOrange),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.deepOrange,
          fontSize: 12,
        ),
      ),
    );
  }
}
