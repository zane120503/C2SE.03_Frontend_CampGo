import 'package:flutter/foundation.dart';

class Cart {
  final String? id;
  final List<CartItem>? items;
  final double? totalPrice;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cart({
    this.id,
    this.items,
    this.totalPrice,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'],
      items: (json['items'] as List?)?.map((item) => CartItem.fromJson(item)).toList(),
      totalPrice: json['totalPrice']?.toDouble(),
      userId: json['userId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'items': items?.map((item) => item.toJson()).toList(),
      'totalPrice': totalPrice,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageURL;
  final double discount;
  final double discountedPrice;
  final bool isSelected;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageURL,
    this.discount = 0,
    double? discountedPrice,
    this.isSelected = true,
  }) : this.discountedPrice = discountedPrice ?? price * (1 - discount / 100);

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 0,
      imageURL: json['imageURL'] ?? '',
      discount: (json['discount'] ?? 0.0).toDouble(),
      isSelected: json['isSelected'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageURL': imageURL,
      'discount': discount,
      'discountedPrice': discountedPrice,
      'isSelected': isSelected,
    };
  }
}

class CartModel extends ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.discountedPrice * item.quantity;
    });
    return total;
  }

  void updateFromCartItemSamples(List<dynamic> cartItems) {
    _items.clear();
    for (var item in cartItems) {
      if (item.isSelected) {
        _items[item.id] = CartItem(
          id: item.id,
          productId: item.id,
          productName: item.name,
          price: item.price,
          quantity: item.quantity,
          imageURL: item.image,
          discount: item.discount.toDouble(),
          isSelected: item.isSelected,
        );
      }
    }
    notifyListeners();
  }

  void addItem({
    required String productId,
    required String productName,
    required double price,
    required String imageURL,
    double discount = 0,
    int quantity = 1,
  }) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          productId: productId,
          productName: productName,
          price: price,
          quantity: existingItem.quantity + quantity,
          imageURL: imageURL,
          discount: discount,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(),
          productId: productId,
          productName: productName,
          price: price,
          quantity: quantity,
          imageURL: imageURL,
          discount: discount,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        _items.update(
          productId,
          (existingItem) => CartItem(
            id: existingItem.id,
            productId: existingItem.productId,
            productName: existingItem.productName,
            price: existingItem.price,
            quantity: quantity,
            imageURL: existingItem.imageURL,
            discount: existingItem.discount,
          ),
        );
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items = {};
    notifyListeners();
  }
} 