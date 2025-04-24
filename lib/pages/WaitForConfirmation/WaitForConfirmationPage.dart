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
      
      print('Loading orders...');
      final response = await APIService.getOrders();
      print('Orders API response: $response');
      
      if (response != null && response['success'] == true) {
        final List<dynamic> ordersData = response['data'] ?? [];
        print('Number of orders received: ${ordersData.length}');
        
        final filteredOrders = ordersData
            .where((order) {
              print('Processing order: ${order['_id']}');
              print('Order status: ${order['delivery_status']}');
              
              // Chỉ lấy những đơn hàng có delivery_status là Pending
              return order['delivery_status'] == 'Pending';
            })
            .map((e) => e as Map<String, dynamic>)
            .toList();
            
        print('Number of filtered orders: ${filteredOrders.length}');
        
        setState(() {
          _orders = filteredOrders;
        });
      } else {
        print('Failed to load orders: ${response?['message']}');
        setState(() {
          _orders = [];
        });
      }
    } catch (e, stackTrace) {
      print('Error loading orders: $e');
      print('Stack trace: $stackTrace');
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
              'discount': int.tryParse(product['product']?['discount']?.toString() ?? '0') ?? 0,
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
        'total_amount': _calculateTotalAmount(orderData),
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
            content: Text('Unable to open order information',
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
    return Scaffold(
      backgroundColor: const Color(0xFFEDECF2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
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
    List<dynamic> products = orderData['products'] ?? [];
    bool hasMultipleProducts = products.length > 1;
    var firstProduct = products.first;
    
    double price = (firstProduct['product']['price'] ?? 0).toDouble();
    int discount = (firstProduct['product']['discount'] ?? 0).toInt();
    int quantity = (firstProduct['quantity'] ?? 0).toInt();
    
    // Tính giá sau khi giảm giá
    double finalPrice = discount > 0 ? price * (1 - discount / 100) : price;
    String productDetail = '';
    
    if (discount > 0) {
      productDetail = 'Price: \$${(finalPrice).toStringAsFixed(2)} (-$discount%) | Original: \$${price.toStringAsFixed(2)}';
    } else {
      productDetail = 'Price: \$${price.toStringAsFixed(2)}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 10, left: 10),
      child: InkWell(
        onTap: () {
          _navigateToOrderInformation(orderData);
        },
        child: Card(
          color: Colors.white,
          child: _buildProductContent(
            headerText: 'Order ID: ${orderData['_id']}',
            imageUrl: firstProduct['product']['imageURL'] ?? '',
            productName: firstProduct['product']['productName'] ?? '',
            productDetail: productDetail,
            totalAmountLabel: hasMultipleProducts 
                ? 'Total amount (${products.length} products):'
                : 'Amount:',
            totalAmount: _formatPrice(_calculateTotalAmount(orderData)),
            quantity: firstProduct['quantity'].toString(),
            tags: ['Pending'],
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

