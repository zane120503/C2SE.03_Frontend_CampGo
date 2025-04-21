import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:CampGo/services/api_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final double discountedPrice;
  final String image;
  int quantity;
  bool isSelected;
  final int discount;
  final int stockQuantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.discountedPrice,
    required this.image,
    required this.quantity,
    required this.isSelected,
    required this.discount,
    required this.stockQuantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    try {
      final product = json['product'];
      final price = (product['price'] ?? 0.0).toDouble();
      final discount = product['discount'] ?? 0;
      final discountedPrice = price * (1 - discount / 100);
      
      return CartItem(
        id: product['_id'] ?? '',
        name: product['productName'] ?? '',
        price: price,
        discountedPrice: discountedPrice,
        image: product['imageURL'] ?? 'assets/images/placeholder.png',
        quantity: json['quantity'] ?? 1,
        isSelected: false,
        discount: discount,
        stockQuantity: product['stockQuantity'] ?? 0,
      );
    } catch (e) {
      print('Error parsing CartItem: $e');
      return CartItem(
        id: '',
        name: 'Error Item',
        price: 0.0,
        discountedPrice: 0.0,
        image: 'assets/images/placeholder.png',
        quantity: 1,
        isSelected: false,
        discount: 0,
        stockQuantity: 0,
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
      setState(() => isLoading = true);
      
      final response = await APIService.getCart();
      print('Get cart response: $response');

      if (response['success'] == true && response['data'] != null) {
        final cartData = response['data'];
        final items = cartData['items'] as List<dynamic>? ?? [];
        
        setState(() {
          cartItems = items.map((item) {
            try {
              final product = item['product'];
              if (product == null) {
                print('Warning: Product is null in cart item');
                return null;
              }

              final price = (item['price'] ?? 0.0).toDouble();
              final quantity = (item['quantity'] ?? 1).toInt();
              final discount = (product['discount'] ?? 0).toInt();
              final discountedPrice = price * (1 - discount / 100);

              // Xử lý URL hình ảnh
              String imageUrl = '';
              if (product['images'] != null && product['images'] is List && product['images'].isNotEmpty) {
                var firstImage = product['images'][0];
                if (firstImage is Map && firstImage.containsKey('url')) {
                  imageUrl = firstImage['url'].toString();
                }
              }

              print('Cart item image URL: $imageUrl');

              return CartItem(
                id: product['_id'] ?? '',
                name: product['productName'] ?? '',
                price: price,
                discountedPrice: discountedPrice,
                image: imageUrl.isNotEmpty ? imageUrl : 'assets/images/placeholder.png',
                quantity: quantity,
                isSelected: false,
                discount: discount,
                stockQuantity: product['stockQuantity'] ?? 0,
              );
            } catch (e) {
              print('Error parsing cart item: $e');
              return null;
            }
          }).where((item) => item != null).cast<CartItem>().toList();
          
          isLoading = false;
        });
        
        _updateTotalPrice();
        print('Loaded ${cartItems.length} items');
      } else {
        setState(() {
          cartItems = [];
          isLoading = false;
        });
        
        if (mounted && response['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        isLoading = false;
        cartItems = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải giỏ hàng: ${e.toString()}'),
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

  void _updateQuantity(int index, int change) async {
    if (index < 0 || index >= cartItems.length) return;
    
    final item = cartItems[index];
    final newQuantity = (item.quantity + change).clamp(1, item.stockQuantity);
    
    if (newQuantity != item.quantity) {
      setState(() {
        item.quantity = newQuantity;
        _updateTotalPrice();
      });
      
      await _updateQuantityOnServer(item.id, newQuantity);
    }
  }

  Future<void> _updateQuantityOnServer(String productId, int quantity) async {
    try {
      final response = await APIService.updateCartItem(productId, quantity);
      if (!response['success']) {
        throw Exception(response['message'] ?? 'Không thể cập nhật số lượng');
      }
      
      // Refresh cart data after successful update
      await loadCartItems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Cập nhật số lượng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating quantity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật số lượng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelection(int index, bool? value) {
    if (index < 0 || index >= cartItems.length) return;
    
    setState(() {
      cartItems[index].isSelected = value ?? false;
      
      if (cartItems[index].isSelected) {
        selectedProductIds.add(cartItems[index].id);
      } else {
        selectedProductIds.remove(cartItems[index].id);
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
        selectedProductIds = cartItems.map((item) => item.id).toSet();
      } else {
        selectedProductIds.clear();
      }
      
      _updateTotalPrice();
    });
  }

  void _removeItem(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    
    final item = cartItems[index];
    
    // Hiển thị dialog xác nhận xóa
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa ${item.name} khỏi giỏ hàng?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response = await APIService.removeFromCart(item.id);
      
      if (response['success']) {
        setState(() {
          if (item.isSelected) {
            selectedProductIds.remove(item.id);
          }
          cartItems.removeAt(index);
          isAllSelected = cartItems.isNotEmpty ? cartItems.every((item) => item.isSelected) : false;
          _updateTotalPrice();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Đã xóa sản phẩm khỏi giỏ hàng'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Không thể xóa sản phẩm');
      }
    } catch (e) {
      print('Error removing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa sản phẩm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          // Checkbox
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
              color: Colors.grey[200],
            ),
            child: item.image.startsWith('http') 
              ? Image.network(
                  item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey[400],
                    );
                  },
                )
              : Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Colors.grey[400],
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  '\$${item.discountedPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2321),
                  ),
                ),
              ],
            ),
          ),
          
          // Phần tăng giảm số lượng và icon delete
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