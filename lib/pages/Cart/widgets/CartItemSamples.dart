import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:CampGo/services/api_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final double originalPrice;
  final String image;
  int quantity;
  bool isSelected;
  final int discount;
  final int stockQuantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
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
      final originalPrice = (product['originalPrice'] ?? product['price'] ?? 0.0).toDouble();
      final discount = product['discount'] ?? 0;
      
      return CartItem(
        id: product['_id'] ?? '',
        name: product['productName'] ?? '',
        price: price,
        originalPrice: originalPrice,
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
        originalPrice: 0.0,
        image: 'assets/images/placeholder.png',
        quantity: 1,
        isSelected: false,
        discount: 0,
        stockQuantity: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'quantity': quantity,
      'image': image,
      'discount': discount,
    };
  }
}

class CartItemSamplesController {
  _CartItemSamplesState? _state;

  void _setState(_CartItemSamplesState state) {
    _state = state;
  }

  Map<String, dynamic>? getSelectedItemsData() {
    return _state?.getSelectedItemsData();
  }
}

class CartItemSamples extends StatefulWidget {
  final Function(Set<String>) onSelectedProductsChanged;
  final Function(double) onTotalPriceChanged;
  final CartItemSamplesController? controller;

  const CartItemSamples({
    Key? key, 
    required this.onSelectedProductsChanged,
    required this.onTotalPriceChanged,
    this.controller,
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
    widget.controller?._setState(this);
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
              final originalPrice = (product['originalPrice'] ?? price).toDouble();

              String imageUrl = '';
              if (product['images'] != null && product['images'] is List && product['images'].isNotEmpty) {
                var firstImage = product['images'][0];
                if (firstImage is Map && firstImage.containsKey('url')) {
                  imageUrl = firstImage['url'].toString();
                }
              }

              return CartItem(
                id: product['_id'] ?? '',
                name: product['productName'] ?? '',
                price: price,
                originalPrice: originalPrice,
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
            content: Text('Unable to load cart: ${e.toString()}',
            textAlign: TextAlign.center,
            ),   
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateTotalPrice() {
    double totalPrice = calculateTotalPrice();
    widget.onTotalPriceChanged(totalPrice);
    widget.onSelectedProductsChanged(selectedProductIds);
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
        throw Exception(response['message'] ?? 'Unable to update quantity');    
      }

      await loadCartItems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Update quantity successfully',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating quantity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to update quantity: $e',
            textAlign: TextAlign.center,
            ),
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
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm deletion'),
          content: Text('Are you sure you want to delete ${item.name} from cart?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Cancel',
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
              content: Text(response['message'] ?? 'Product removed from cart',
            textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Cannot delete product');
      }
    } catch (e) {
      print('Error removing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot delete product: $e',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double calculateTotalPrice() {
    return cartItems.fold(0.0, (sum, item) {
      if (item.isSelected) {
        return sum + (item.price * item.quantity);
      }
      return sum;
    });
  }

  List<CartItem> getSelectedItems() {
    return cartItems.where((item) => item.isSelected).toList();
  }

  Map<String, dynamic> getSelectedItemsData() {
    final selectedItems = getSelectedItems();
    return {
      'selectedItems': selectedItems.map((item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'originalPrice': item.originalPrice,
        'quantity': item.quantity,
        'image': item.image,
        'discount': item.discount,
      }).toList(),
      'totalPrice': calculateTotalPrice(),
    };
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
          padding: const EdgeInsets.only(left: 20, right: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Checkbox(
                value: isAllSelected,
                activeColor: const Color(0xFF2B2321),
                onChanged: _toggleSelectAll,
              ),
              Text(
                "Select All",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
      height: 120,
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Transform.translate(
            offset: Offset(-5, 0),
            child: Checkbox(
              value: item.isSelected,
              activeColor: Color(0xFF2B2321),
              onChanged: (value) => _toggleSelection(index, value),
            ),
          ),
          Container(
            height: 70,
            width: 70,
            margin: EdgeInsets.only(right: 15),
            child: item.image.startsWith('http')
              ? FadeInImage.assetNetwork(
                  placeholder: "assets/images/placeholder.png",
                  image: item.image,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Image.asset("assets/images/placeholder.png");
                  },
                  fit: BoxFit.cover,
                )
              : Image.asset("assets/images/placeholder.png"),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B2321),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${item.price.toStringAsFixed(2)}đ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2321),
                        ),
                      ),
                      SizedBox(width: 4),
                      if (item.originalPrice > item.price)
                        Text(
                          "-${item.discount}%",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  if (item.originalPrice > item.price)
                    Text(
                      "${item.originalPrice.toStringAsFixed(2)}đ",
                      style: TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _removeItem(index),
                  child: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _updateQuantity(index, 1),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.plus,
                          size: 15,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "${item.quantity}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2321),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _updateQuantity(index, -1),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.minus,
                          size: 15,
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
}