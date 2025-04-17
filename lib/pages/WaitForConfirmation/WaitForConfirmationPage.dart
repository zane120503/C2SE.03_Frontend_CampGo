import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:CampGo/api/api.service.dart';
import 'package:CampGo/services/data_service.dart';
import 'package:CampGo/model/order_model.dart';
import 'package:CampGo/pages/WaitForConfirmation/widgets/OrderInformationPage.dart';
import 'package:flutter/services.dart';

class WaitForConfirmationPage extends StatefulWidget {
  const WaitForConfirmationPage({super.key});

  @override
  State<WaitForConfirmationPage> createState() => _WaitForConfirmationState();
}

class _WaitForConfirmationState extends State<WaitForConfirmationPage> {
  final Map<String, bool> _expandedOrders = {};
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final response = await APIService.getOrders();
      print('Orders API response: $response');
      
      if (response != null && response['success'] == true) {
        final List<dynamic> ordersData = response['data'] ?? [];
        
        setState(() {
          _orders = ordersData
              .where((order) {
                // Chỉ lấy các đơn hàng chờ xác nhận
                return !order['waiting_confirmation'] && 
                       ((order['payment_method'] == 'Payment Upon Receipt' && 
                         order['payment_status'] == 'Pending' && 
                         order['delivery_status'] == 'Pending') ||
                        (order['payment_method'] == 'Credit Card' && 
                         order['payment_status'] == 'Completed' && 
                         order['delivery_status'] == 'Pending'));
              })
              .map((e) => e as Map<String, dynamic>)
              .toList();
        });
      } else {
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
      int quantity = (product['quantity'] ?? 0).toInt();
      total += price * quantity;
    }
    
    return total;
  }

  void _removeOrder(String orderId) {
    setState(() {
      _orders.removeWhere((order) => order['_id'] == orderId);
    });
  }

  Future<void> _navigateToOrderInformation(Map<String, dynamic> orderData) async {
    try {
      print('Original order data from API: $orderData'); // Debug log

      // Chuyển đổi dữ liệu sang Map<String, dynamic>
      final Map<String, dynamic> convertedOrderData = {
        '_id': orderData['_id']?.toString() ?? '',
        'status': orderData['delivery_status']?.toString().toLowerCase() ?? 'pending',
        'payment_method': orderData['payment_method']?.toString() ?? 'Payment Upon Receipt',
        'products': (orderData['products'] as List?)?.map((product) {
          return {
            'product': {
              'productName': product['product']?['productName']?.toString() ?? '',
              'description': product['product']?['description']?.toString() ?? '',
              'price': double.tryParse(product['product']?['price']?.toString() ?? '0') ?? 0.0,
              'imageURL': product['product']?['imageURL']?.toString() ?? '',
            },
            'quantity': int.tryParse(product['quantity']?.toString() ?? '1') ?? 1,
          };
        }).toList() ?? [],
        'address': {
          'fullName': orderData['shipping_address']?['fullName']?.toString() ?? '',
          'phoneNumber': orderData['shipping_address']?['phoneNumber']?.toString() ?? '',
          'street': orderData['shipping_address']?['street']?.toString() ?? '',
          'ward': orderData['shipping_address']?['ward']?.toString() ?? '',
          'district': orderData['shipping_address']?['district']?.toString() ?? '',
          'city': orderData['shipping_address']?['city']?.toString() ?? '',
        },
      };

      print('Converted order data: $convertedOrderData'); // Debug log

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderInformation(
            orderData: convertedOrderData,
            onOrderCancelled: () {
              _loadOrders();
            },
          ),
        ),
      );

      if (result == true) {
        await _loadOrders();
      }
    } catch (e, stackTrace) {
      print('Error navigating to order information: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở thông tin đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              'Waiting For Confirmation',
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
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(
                        child: Text(
                          'No orders are waiting for confirmation',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: _orders.map((orderData) {
                            return _buildOrderSection(orderData);
                          }).toList(),
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSection(Map<String, dynamic> orderData) {
    bool isExpanded = _expandedOrders[orderData['_id']] ?? false;
    List<dynamic> products = orderData['products'] ?? [];
    bool hasMultipleProducts = products.length > 1;

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 10, left: 10),
      child: InkWell(
        onTap: () {
          _navigateToOrderInformation(orderData);
        },
        child: Card(
          color: Colors.white,
          child: Column(
            children: [
              if (products.isNotEmpty)
                _buildProductContent(
                  headerText: 'Order ID: ${orderData['_id']}',
                  imageUrl: products.first['product']['imageURL'] ?? '',
                  productName: products.first['product']['productName'] ?? '',
                  productDetail: products.first['product']['description'] ?? '',
                  totalAmountLabel: hasMultipleProducts && !isExpanded
                      ? 'Total amount (${products.length} products):'
                      : 'Amount:',
                  totalAmount: hasMultipleProducts && !isExpanded
                      ? _formatPrice(_calculateTotalAmount(orderData))
                      : _formatPrice((products.first['amount'] ?? 0).toDouble()),
                  quantity: products.first['quantity'].toString(),
                  tags: ['Pending'],
                  showExpandButton: hasMultipleProducts,
                  isExpanded: isExpanded,
                  onExpandPressed: () {
                    setState(() {
                      _expandedOrders[orderData['_id']] = !isExpanded;
                    });
                  },
                ),
              if (hasMultipleProducts && isExpanded)
                ...products.skip(1).map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: _buildProductContent(
                      headerText: '',
                      imageUrl: product['product']['imageURL'] ?? '',
                      productName: product['product']['productName'] ?? '',
                      productDetail: product['product']['description'] ?? '',
                      totalAmountLabel: 'Amount:',
                      totalAmount: _formatPrice((product['amount'] ?? 0).toDouble()),
                      quantity: product['quantity'].toString(),
                      tags: ['Pending'],
                      showExpandButton: false,
                      isExpanded: false,
                      onExpandPressed: null,
                    ),
                  );
                }),
              if (hasMultipleProducts)
                Center(
                  child: IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.deepOrange,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _expandedOrders[orderData['_id']] = !isExpanded;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductContent({
    required String headerText,
    required String imageUrl,
    required String productName,
    required String productDetail,
    required String totalAmountLabel,
    required String totalAmount,
    required String quantity,
    required List<String> tags,
    required bool showExpandButton,
    required bool isExpanded,
    required Function()? onExpandPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerText.isNotEmpty) _buildProductHeader(headerText),
          const SizedBox(height: 10),
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
                        size: 40,
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
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productDetail,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 91, 91, 91),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity: $quantity',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 91, 91, 91),
                            fontSize: 14,
                          ),
                        ),
                        _buildTag(tags.first),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTotalAmountSection(totalAmountLabel, totalAmount),
        ],
      ),
    );
  }

  Widget _buildProductHeader(String headerText) {
    return Row(
      children: [
        const Spacer(),
        Text(
          headerText,
          style: const TextStyle(
            color: Colors.deepOrange,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTags(List<String> tags) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: tags.map((tag) {
        return Padding(
          padding: const EdgeInsets.only(right: 1.0),
          child: _buildTag(tag),
        );
      }).toList(),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildTotalAmountSection(String label, String totalAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
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
    );
  }

  Widget _buildExpandedProductItem(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['product']['imageURL'] ?? '',
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
                        fontSize: 18,
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
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${product['quantity']}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.deepOrange),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Pending',
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${(product['amount'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

