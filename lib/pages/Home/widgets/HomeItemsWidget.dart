import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:CampGo/pages/Product/ProductPage.dart';

class Product {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final int discountPercentage;
  final double rating;
  final int soldCount;
  final String category; 

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.soldCount,
    required this.category, 
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? '',
        price: json['price'] is double ? json['price'] : double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
        discountPercentage: json['discountPercentage'] is int ? json['discountPercentage'] : int.tryParse(json['discountPercentage']?.toString() ?? '') ?? 0,
        rating: json['rating'] is double ? json['rating'] : double.tryParse(json['rating']?.toString() ?? '') ?? 0.0,
        soldCount: json['soldCount'] is int ? json['soldCount'] : int.tryParse(json['soldCount']?.toString() ?? '') ?? 0,
        category: json['category']?.toString() ?? '',
      );
    } catch (e) {
      print('Lỗi khi parse JSON: $e');
      return Product(
        id: 0,
        name: '',
        imageUrl: '',
        price: 0.0,
        discountPercentage: 0,
        rating: 0.0,
        soldCount: 0,
        category: '',
      );
    }
  }
}

class HomeItemWidget extends StatefulWidget {
  const HomeItemWidget({super.key});

  @override
  State<HomeItemWidget> createState() => _HomeItemWidgetState();
}

class _HomeItemWidgetState extends State<HomeItemWidget> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final String response = await rootBundle.loadString('assets/data/Product.json');
      final data = await json.decode(response);
      
      if (data['products'] != null) {
        setState(() {
          products = (data['products'] as List)
              .map((product) => Product.fromJson(product))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi khi tải sản phẩm: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductItem(products[index]);
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (product.discountPercentage > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "-${product.discountPercentage}%",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Icon(
                Icons.favorite_border,
                size: 20,
                color: Colors.red,
              ),
            ],
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product',
                arguments: {'productId': product.id.toString()},
              );
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              child: Image.asset(
                product.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            alignment: Alignment.centerLeft,
            child: Text(
              product.name,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              "${product.price.toInt()}đ", // Chuyển sang số nguyên
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${product.soldCount} đã bán",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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