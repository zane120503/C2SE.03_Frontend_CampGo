import 'package:flutter/material.dart';
import 'package:CampGo/api/api.service.dart';

class OrderInformation extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onOrderCancelled;

  const OrderInformation({
    super.key,
    required this.orderData,
    this.onOrderCancelled,
  });

  @override
  _OrderInformationState createState() => _OrderInformationState();
}

class _OrderInformationState extends State<OrderInformation> {
  bool _isCancelling = false;

  Future<void> _cancelOrder() async {
    try {
      setState(() {
        _isCancelling = true;
      });

      final orderId = widget.orderData['_id'];
      if (orderId == null) {  
        throw Exception('Order ID not found');    
      }

      print('Cancelling order with ID: $orderId'); // Debug log
      final response = await APIService.cancelOrder(orderId.toString());
      print('Cancel order response: $response'); // Debug log
      
      if (response != null && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onOrderCancelled?.call();
          Navigator.of(context).pop(true);
        }
      } else {
        final errorMessage = response?['message'] ?? 'Cannot cancel order';
        print('Cancel order error: $errorMessage'); // Debug log
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error cancelling order: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  double _calculateTotalAmount() {
    double total = 0;
    List<dynamic> products = widget.orderData['products'] ?? [];
    
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
    print('Order Data: ${widget.orderData}'); // Thêm log để debug
    final orderStatus = widget.orderData['delivery_status']?.toString().toLowerCase() ?? 'pending';
    final paymentMethod = widget.orderData['payment_method'] ?? 'Payment Upon Receipt';
    final shippingAddress = widget.orderData['address'] ?? {};
    final products = widget.orderData['products'] ?? [];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(top: 5.0),
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
            margin: const EdgeInsets.only(top: 5.0),
            child: const Text(
              'Order Information',
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
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    _buildStatusSection(orderStatus, paymentMethod),
                    _buildAddressSection(shippingAddress),
                    _buildShopSection(products),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xFFF5F5F5),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String status, String paymentMethod) {
    String statusText;
    Color statusColor;
    String paymentText;
    
    switch (status) {
      case 'pending':
        statusText = 'Waiting for confirmation';
        statusColor = Colors.orange;
        break;
      case 'confirmed':
        statusText = 'Confirmed';
        statusColor = Colors.blue;
        break;
      case 'shipping':
        statusText = 'Shipping';
        statusColor = Colors.teal;
        break;
      case 'delivered':
        statusText = 'Delivered';
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusText = 'Cancelled';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'Unspecified';
        statusColor = Colors.grey;
    }

    // Xử lý text phương thức thanh toán
    switch (paymentMethod.toLowerCase()) {
      case 'payment upon receipt':
        paymentText = 'Payment Upon Receipt';
        break;
      case 'credit card':
        paymentText = 'Credit Card';
        break;
      default:
        paymentText = paymentMethod;
    }

    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  paymentText,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> address) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Address',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${address['fullName']} - ${address['phoneNumber']}'),
                    Text('${address['street']}, ${address['ward']}, ${address['district']}, ${address['city']}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildShopSection(List<dynamic> products) {
    return Container(
      padding: const EdgeInsets.only(right: 8, left: 8, bottom: 15),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          ...products.map((product) {
            return Column(
              children: [
                _buildProductItem(
                  product['product']['productName'] ?? '',
                  product['product']['description'] ?? '',
                  (product['product']['price'] ?? 0).toDouble(),
                  product['quantity'] ?? 1,
                  product['product']['imageURL'] ?? '',
                ),
                if (product != products.last) const Divider(),
              ],
            );
          }),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total amount:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_calculateTotalAmount().toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    String title,
    String description,
    double price,
    int quantity,
    String imageUrl,
  ) {
    // Tính toán giá sau khi giảm giá từ dữ liệu sản phẩm
    List<dynamic> products = widget.orderData['products'] ?? [];
    var productData = products.firstWhere(
      (p) => p['product']['productName'] == title,
      orElse: () => {'product': {'discount': 0}},
    );
    
    int discount = (productData['product']['discount'] ?? 0).toInt();
    double finalPrice = discount > 0 ? price * (1 - discount / 100) : price;

    return Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 30,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 60,
                          height: 60,
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
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 30,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (discount > 0) Row(
                    children: [
                      Text(
                        '\$${(finalPrice * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${(price * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
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
                          ),
                        ),
                      ),
                    ],
                  ) else Text(
                    '\$${(price * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'x$quantity',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Chỉ hiển thị nút hủy đơn hàng nếu trạng thái là 'pending'
    if (widget.orderData['status'] != 'pending') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(right: 20, left: 20, top: 20, bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isCancelling)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            ElevatedButton(
              onPressed: _cancelOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Cancel Order'),
            ),
        ],
      ),
    );
  }
}
