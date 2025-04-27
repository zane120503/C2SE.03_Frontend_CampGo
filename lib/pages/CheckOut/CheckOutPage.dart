import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:CampGo/pages/Address/AddressPage.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/models/card_model.dart';
import 'package:CampGo/pages/Card%20Account/CreditCardPage.dart';
import 'package:CampGo/pages/Cart/widgets/CartItemSamples.dart';
import 'package:CampGo/pages/WaitForConfirmation/WaitForConfirmationPage.dart';

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
  final double discountedPrice;
  final int quantity;
  final String image;
  final int discount;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.discountedPrice,
    required this.quantity,
    required this.image,
    required this.discount,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: (json['price'] ?? 0.0).toDouble(),
      discountedPrice: (json['discountedPrice'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
      image: json['image'] ?? '',
      discount: json['discount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'discount': discount,
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
  final Map<String, dynamic>? selectedItemsData;
  final CartItemSamplesController? cartController;

  const CheckoutPage({
    Key? key,
    required this.selectedProductIds,
    required this.totalAmount,
    this.selectedItemsData,
    this.cartController,
  }) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final APIService apiService = APIService();
  AddressUser? _defaultAddress;
  CardModel? _defaultCard;
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

    // Thêm listener để reload dữ liệu khi widget được focus lại
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final focusNode = FocusNode();
        focusNode.addListener(() {
          if (focusNode.hasFocus && mounted) {
            _loadData();
          }
        });
        FocusScope.of(context).requestFocus(focusNode);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Nếu có dữ liệu từ CartItemSamples, sử dụng nó
      if (widget.selectedItemsData != null) {
        final items = widget.selectedItemsData!['selectedItems'] as List;
        _cart = Cart(items: items.map((item) => CartItem.fromJson(item)).toList());
        subTotal = widget.selectedItemsData!['totalPrice'] as double;
        total = subTotal + shippingFee;
      } else {
        // Nếu không có dữ liệu, gọi API
        final checkoutData = await DataService.getCheckoutData();
        final itemsList = checkoutData['items'] as List;
        final allItems = itemsList
            .map((item) => CartItem.fromJson(item))
            .where((item) => widget.selectedProductIds.contains(item.id.toString()))
            .toList();
        _cart = Cart(items: allItems);
        shippingFee = (checkoutData['shippingFee'] ?? 30.0).toDouble();
        subTotal = (checkoutData['subTotal'] ?? widget.totalAmount).toDouble();
        total = (checkoutData['total'] ?? (subTotal + shippingFee)).toDouble();
      }

      // Lấy địa chỉ mặc định từ API
      try {
        final addressResponse = await apiService.getAddresses();
        if (addressResponse['success'] == true) {
          final List<dynamic> addressData = addressResponse['data'] ?? [];
          if (addressData.isNotEmpty) {
            final defaultAddress = addressData.firstWhere(
              (address) => address['isDefault'] == true,
              orElse: () => addressData.first,
            );

            _defaultAddress = AddressUser(
              id: defaultAddress['_id'] ?? '',
              fullName: defaultAddress['fullName'] ?? '',
              phoneNumber: defaultAddress['phoneNumber'] ?? '',
              streetAddress: defaultAddress['street'] ?? '',
              ward: defaultAddress['ward'] ?? '',
              district: defaultAddress['district'] ?? '',
              province: defaultAddress['city'] ?? '',
              isDefault: defaultAddress['isDefault'] ?? false,
            );
          }
        }
      } catch (e) {
        print('Error loading default address: $e');
      }

      // Load default card
      try {
        final cardResponse = await apiService.getAllCards();
        if (cardResponse['success'] == true) {
          final List<dynamic> cardsData = cardResponse['data'] ?? [];
          if (cardsData.isNotEmpty) {
            final defaultCard = cardsData.firstWhere(
              (card) => card['is_default'] == true,
              orElse: () => cardsData.first,
            );

            _defaultCard = CardModel(
              id: defaultCard['_id'] ?? '',
              userId: defaultCard['user_id'] ?? '',
              cardNumber: defaultCard['card_number'] ?? '',
              cardHolderName: defaultCard['card_name'] ?? '',
              cardType: defaultCard['card_type'] ?? 'VISA',
              lastFourDigits: defaultCard['card_number']?.substring(defaultCard['card_number'].length - 4) ?? '',
              expiryMonth: defaultCard['card_exp_month']?.toString() ?? '',
              expiryYear: defaultCard['card_exp_year']?.toString() ?? '',
              cvv: defaultCard['card_cvc'] ?? '',
              isDefault: defaultCard['is_default'] ?? false,
              createdAt: defaultCard['createdAt'] != null ? DateTime.parse(defaultCard['createdAt']) : null,
              updatedAt: defaultCard['updatedAt'] != null ? DateTime.parse(defaultCard['updatedAt']) : null,
              v: defaultCard['__v'] ?? 0,
            );
          }
        }
      } catch (e) {
        print('Error loading default card: $e');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load data: $e',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCheckout() async {
    try {
      if (_defaultAddress == null) {
        throw Exception('Please select a shipping address');
      }

      if (_cart?.items == null || _cart!.items!.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Chuẩn bị dữ liệu đơn hàng
      Map<String, dynamic> orderData = {
        'paymentMethod': _selectedPaymentMethod,
        'selectedProducts': _cart?.items?.map((item) => item.id).toList() ?? [],
      };

      // Log chi tiết dữ liệu
      print('Sending order data:');
      print('Payment Method: ${orderData['paymentMethod']}');
      print('Selected Products: ${orderData['selectedProducts']}');

      // Gọi API tạo đơn hàng
      final result = await APIService.createOrder(orderData);
      print('Create order response: $result');

      if (result['success'] == true) {
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
                    'Payment successful',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your order has been paid successfully. '
                    'We will contact you soon to deliver.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.of(context).pop(true); // Return to CartPage with success
                      
                      // Chờ một chút để đảm bảo đơn hàng đã được tạo xong
                      await Future.delayed(Duration(seconds: 1));
                      
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WaitForConfirmationPage(),
                          ),
                        );
                      }
                    },
                    child: Text('Đóng'),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        throw Exception(result['message'] ?? 'Cannot create order');
      }
    } catch (e) {
      print('Error during checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
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
          child: Text('No products in the cart',
          textAlign: TextAlign.center,
          ),
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
            height: 270,
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
            child: item.image.startsWith('http')
                ? Image.network(
                    item.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[500],
                    ),
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
                  'Quantity: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 65, 65, 65),
                  ),
                ),
                Row(
                  children: [
                      Padding(
                        padding: EdgeInsets.only(left: 0),
                        child: Text(
                          '${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 32, 32, 32),
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
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping To',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2321),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddressPage()),
                  );
                  
                  // Reload dữ liệu khi quay về từ AddressPage
                  if (mounted) {
                    setState(() => _isLoading = true);
                    await _loadData();
                  }
                },
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 120,
                        child: Center(
                          child: Icon(
                            Icons.location_on,
                            color: const Color(0xFF2B2321),
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
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
                            SizedBox(height: 8),
                            Text(
                              _defaultAddress!.phoneNumber,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color.fromARGB(255, 53, 53, 53),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _defaultAddress!.streetAddress,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color.fromARGB(255, 53, 53, 53),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_defaultAddress!.ward}, ${_defaultAddress!.district}, ${_defaultAddress!.province}',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color.fromARGB(255, 53, 53, 53),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_location_alt,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add shipping address',
                    style: TextStyle(
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
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2321),
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
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Credit Card'),
                if (_defaultCard != null)
                  Text(
                    '**** ${_defaultCard!.lastFourDigits}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
            value: 'Credit Card',
            groupValue: _selectedPaymentMethod,
            activeColor: Color(0xFF2B2321),
            onChanged: (value) async {
              setState(() => _selectedPaymentMethod = value.toString());
              if (_defaultCard == null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreditCardPage()),
                );
                if (result == true) {
                  await _loadData();
                }
              }
            },
          ),
          if (_selectedPaymentMethod == 'Credit Card')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_defaultCard != null)
                    Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: Icon(Icons.credit_card),
                        title: Text(_defaultCard!.cardHolderName ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('**** **** **** ${_defaultCard!.lastFourDigits}'),
                            Text('Expires: ${_defaultCard!.expiryMonth}/${_defaultCard!.expiryYear}'),
                          ],
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreditCardPage()),
                            );
                            if (result == true) {
                              await _loadData();
                            }
                          },
                          child: Text(
                            'Change',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreditCardPage()),
                        );
                        if (result == true) {
                          await _loadData();
                        }
                      },
                      child: Text('Add Credit Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
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