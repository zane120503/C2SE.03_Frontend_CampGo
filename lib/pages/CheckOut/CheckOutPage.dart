import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class AddressUser {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String streetAddress;
  final String ward;
  final String district;
  final String province;
  final bool isDefault;

  AddressUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.ward,
    required this.district,
    required this.province,
    required this.isDefault,
  });

  factory AddressUser.fromJson(Map<String, dynamic> json) {
    return AddressUser(
      id: json['id'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      streetAddress: json['streetAddress'],
      ward: json['ward'],
      district: json['district'],
      province: json['province'],
      isDefault: json['isDefault'],
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      images: List<String>.from(json['images']),
    );
  }
}

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final Product? product;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'product': product != null ? {
        'id': product!.id,
        'name': product!.name,
        'price': product!.price,
        'images': product!.images,
      } : null,
    };
  }
}

class Cart {
  List<CartItem>? items;

  Cart({this.items});

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: json['items'] != null
          ? List<CartItem>.from(
              json['items'].map((item) => CartItem.fromJson(item)))
          : null,
    );
  }
}

class DataService {
  static Future<List<Map<String, dynamic>>> getAllAddresses() async {
    final String response = await rootBundle.loadString('assets/data/AddressUser.json');
    final data = await json.decode(response);
    return List<Map<String, dynamic>>.from(data['addresses']);
  }

  static Future<Map<String, dynamic>> getCheckoutData() async {
    final String response = await rootBundle.loadString('assets/data/CheckOut.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> checkout(Map<String, dynamic> checkoutData) async {
    await Future.delayed(Duration(seconds: 1));
    return {'success': true, 'message': 'Checkout successful'};
  }
}

class CheckoutPage extends StatefulWidget {
  final Set<String> selectedProductIds;
  final double totalAmount;

  const CheckoutPage({
    Key? key,
    required this.selectedProductIds,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  AddressUser? _defaultAddress;
  Cart? _cart;
  String _selectedPaymentMethod = 'Payment Upon Receipt';
  bool _isLoading = true;
  final _cardHolderNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpMonthController = TextEditingController();
  final _cardExpYearController = TextEditingController();
  final _cardCVCController = TextEditingController();
  double shippingFee = 30.0;
  double subTotal = 0.0;
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load địa chỉ từ AddressUser.json
      final addressesData = await DataService.getAllAddresses();
      final addresses = addressesData
          .map((addressData) => AddressUser.fromJson(addressData))
          .toList();
      _defaultAddress = addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first
      );

      // Load dữ liệu từ Checkout.json
      final checkoutData = await DataService.getCheckoutData();
      
      // Parse items và lọc theo selectedProductIds
      final itemsList = checkoutData['items'] as List;
      final allItems = itemsList
          .map((item) => CartItem.fromJson(item))
          .where((item) => widget.selectedProductIds.contains(item.id.toString()))
          .toList();

      _cart = Cart(items: allItems);

      // Lấy các giá trị từ Checkout.json
      shippingFee = (checkoutData['shippingFee'] ?? 30.0).toDouble();
      subTotal = (checkoutData['subTotal'] ?? widget.totalAmount).toDouble();
      total = (checkoutData['total'] ?? (subTotal + shippingFee)).toDouble();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCheckout() async {
    try {
      Map<String, dynamic> checkoutData = {
        'paymentMethod': _selectedPaymentMethod,
        'addressId': _defaultAddress?.id,
        'totalPrices': total,
        'products':
            widget.selectedProductIds.map((id) => {'productId': id}).toList(),
      };

      final result = await DataService.checkout(checkoutData);

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.all(16.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80.0,
                ),
                SizedBox(height: 20),
                Text(
                  'Thanh toán thành công',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Đơn hàng của quý khách đã thanh toán thành công. '
                  'Chúng tôi sẽ sớm liên hệ với quý khách để bàn giao sản phẩm, dịch vụ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pushReplacementNamed('/main'); // Navigate to home
                  },
                  child: Text('Đóng'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 12, bottom: 20),
          child: Text(
            'Check Out',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2321),
            ),
          ),
        ),
        backgroundColor: Color(0xFFEDECF2),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddressSection(),
                        _buildCartItems(),
                        _buildPaymentMethod(),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: _buildTotalAndBuyButton(),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItems() {
    if (_cart == null || _cart!.items == null || _cart!.items!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('Không có sản phẩm nào trong giỏ hàng'),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _cart!.items!.length,
              itemBuilder: (context, index) {
                final item = _cart!.items![index];
                return _buildCartItem(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.product?.images[0] ?? 'assets/images/img1.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2321),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Số lượng: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping To',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2321),
            ),
          ),
          SizedBox(height: 8),
          if (_defaultAddress != null)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.radio_button_checked,
                    color: const Color(0xFF2B2321),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _defaultAddress!.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B2321),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _defaultAddress!.phoneNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _defaultAddress!.streetAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${_defaultAddress!.ward}, ${_defaultAddress!.district}, ${_defaultAddress!.province}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold
            )
          ),
          RadioListTile(
            title: Text('Payment Upon Receipt'),
            value: 'Payment Upon Receipt',
            groupValue: _selectedPaymentMethod,
            activeColor: Color(0xFF2B2321),
            onChanged: (value) =>
                setState(() => _selectedPaymentMethod = value.toString()),
          ),
          RadioListTile(
            title: Text('Credit Card'),
            value: 'Credit Card',
            groupValue: _selectedPaymentMethod,
            activeColor: Color(0xFF2B2321),
            onChanged: (value) =>
                setState(() => _selectedPaymentMethod = value.toString()),
          ),
          if (_selectedPaymentMethod == 'Credit Card')
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Column(
                children: [
                  TextField(
                    controller: _cardHolderNameController,
                    decoration: InputDecoration(labelText: 'Card Holder Name'),
                  ),
                  TextField(
                    controller: _cardNumberController,
                    decoration: InputDecoration(labelText: 'Card Number'),
                    keyboardType: TextInputType.number,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cardExpMonthController,
                          decoration: InputDecoration(labelText: 'Exp Month'), 
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cardExpYearController,
                          decoration: InputDecoration(labelText: 'Exp Year'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _cardCVCController,
                    decoration: InputDecoration(labelText: 'CVC'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalAndBuyButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('Shipping Fee', '\$${shippingFee.toStringAsFixed(2)}'),
          SizedBox(height: 8),
          _buildRow('Subtotal', '\$${subTotal.toStringAsFixed(2)}'),
          Divider(thickness: 1, color: Colors.grey[300]),
          _buildRow('Total', '\$${total.toStringAsFixed(2)}', isBold: true),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3E3364),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Payment',
                style: TextStyle(
                  fontSize: 18,
                  color: const Color.fromARGB(255, 215, 159, 54),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF2B2321),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? const Color(0xFF2B2321) : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}