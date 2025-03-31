import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  final String image;
  int quantity;
  bool isSelected;
  final int discount;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
    required this.isSelected,
    required this.discount,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    try {
      return CartItem(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        price: (json['price'] ?? 0.0).toDouble(),
        image: json['image'] ?? 'assets/images/placeholder.png',
        quantity: json['quantity'] ?? 1,
        isSelected: json['isSelected'] ?? false,
        discount: json['discount'] ?? 0,
      );
    } catch (e) {
      print('Error parsing CartItem: $e');
      return CartItem(
        id: 0,
        name: 'Error Item',
        price: 0.0,
        image: 'assets/images/placeholder.png',
        quantity: 1,
        isSelected: false,
        discount: 0,
      );
    }
  }
}

class CartItemSamples extends StatefulWidget {
  final Function(double) onTotalPriceChanged;
  final Function(Set<String>)? onSelectedItemsChanged;
  
  const CartItemSamples({
    Key? key, 
    required this.onTotalPriceChanged,
    this.onSelectedItemsChanged,
  }) : super(key: key);

  @override
  State<CartItemSamples> createState() => _CartItemSamplesState();
}

class _CartItemSamplesState extends State<CartItemSamples> {
  List<CartItem> cartItems = [];
  bool isLoading = true;
  Set<String> selectedProductIds = {};
  bool isAllSelected = false;

  @override
  void initState() {
    super.initState();
    loadCartItems();
  }

  Future<void> loadCartItems() async {
    try {
      final String response = await rootBundle.loadString('assets/data/Cart.json');
      if (response.isEmpty) {
        throw Exception('Cart.json is empty');
      }

      final data = await json.decode(response);
      if (data == null) {
        throw Exception('Failed to parse Cart.json');
      }

      final itemsList = data['cartItems'];
      if (itemsList == null || !(itemsList is List)) {
        throw Exception('Invalid cartItems format in Cart.json');
      }

      setState(() {
        cartItems = List<CartItem>.from(
          itemsList.map((item) => CartItem.fromJson(item))
        ).where((item) => item.id != 0).toList();
        isLoading = false;
      });
      
      _updateTotalPrice();
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        isLoading = false;
        cartItems = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải giỏ hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateTotalPrice() {
    double totalPrice = calculateTotalPrice();
    widget.onTotalPriceChanged(totalPrice);
    
    if (widget.onSelectedItemsChanged != null) {
      widget.onSelectedItemsChanged!(selectedProductIds);
    }
  }

  void _updateQuantity(int index, int change) {
    if (index < 0 || index >= cartItems.length) return;
    
    setState(() {
      cartItems[index].quantity = (cartItems[index].quantity + change).clamp(1, 99);
      _updateTotalPrice();
    });
  }

  void _toggleSelection(int index, bool? value) {
    if (index < 0 || index >= cartItems.length) return;
    
    setState(() {
      cartItems[index].isSelected = value ?? false;
      
      if (cartItems[index].isSelected) {
        selectedProductIds.add(cartItems[index].id.toString());
      } else {
        selectedProductIds.remove(cartItems[index].id.toString());
      }
      
      isAllSelected = cartItems.every((item) => item.isSelected);
      
      _updateTotalPrice();
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      isAllSelected = value ?? false;
      
      for (var item in cartItems) {
        item.isSelected = isAllSelected;
      }
      
      if (isAllSelected) {
        selectedProductIds = cartItems.map((item) => item.id.toString()).toSet();
      } else {
        selectedProductIds.clear();
      }
      
      _updateTotalPrice();
    });
  }

  void _removeItem(int index) {
    if (index < 0 || index >= cartItems.length) return;
    
    setState(() {
      if (cartItems[index].isSelected) {
        selectedProductIds.remove(cartItems[index].id.toString());
      }
      
      cartItems.removeAt(index);
      
      isAllSelected = cartItems.isNotEmpty ? cartItems.every((item) => item.isSelected) : false;
      
      _updateTotalPrice();
    });
  }

  double calculateTotalPrice() {
    return cartItems.fold(0.0, (sum, item) {
      if (item.isSelected) {
        double discountAmount = item.price * (item.discount / 100);
        return sum + (item.price * item.quantity) - (discountAmount * item.quantity);
      }
      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2B2321)),
        ),
      );
    }

    if (cartItems.isEmpty) {
      return const Center(
        child: Text(
          "Giỏ hàng trống",
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF2B2321),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Select All row
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 20,
                child: Checkbox(
                  value: isAllSelected,
                  activeColor: const Color(0xFF2B2321),
                  onChanged: _toggleSelectAll,
                ),
              ),
              SizedBox(width: 10),
              Text(
                "Select All",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2B2321),
                ),
              ),
            ],
          ),
        ),
        
        // Cart items list
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: cartItems.length,
          itemBuilder: (context, index) => buildCartItem(cartItems[index], index),
        ),
      ],
    );
  }

  Widget buildCartItem(CartItem item, int index) {
    double originalPrice = item.price;
    int discountPercentage = item.discount;
    double finalPrice = originalPrice * (1 - discountPercentage / 100);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox thẳng hàng với "Select All"
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: item.isSelected,
              activeColor: const Color(0xFF2B2321),
              onChanged: (value) => _toggleSelection(index, value),
            ),
          ),
          SizedBox(width: 10),
          
          // Hình ảnh sản phẩm
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(item.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 15),
          
          // Thông tin sản phẩm
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2B2321),
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '\$${finalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2321),
                      ),
                    ),
                    if (discountPercentage > 0) ...[
                      SizedBox(width: 8),
                      Text(
                        '-$discountPercentage%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
                if (discountPercentage > 0)
                  Text(
                    '\$${originalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          
          // Phần tăng giảm số lượng và icon delete (đẩy sang phải)
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Icon delete
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                  padding: EdgeInsets.only(left: 20),
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 40),
                // Điều khiển số lượng
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _updateQuantity(index, -1),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.remove_circle_outline, size: 22),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    InkWell(
                      onTap: () => _updateQuantity(index, 1),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.add_circle_outline, size: 22),
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
}