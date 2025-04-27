import 'package:flutter/material.dart';
import 'package:CampGo/pages/Cart/widgets/CartAppBar.dart';
import 'package:CampGo/pages/Cart/widgets/CartBottomNavBar.dart';
import 'package:CampGo/pages/Cart/widgets/CartItemSamples.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/pages/CheckOut/CheckoutPage.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Set<String> selectedProducts = {};
  double totalPrice = 0.0;
  final CartItemSamplesController _cartController = CartItemSamplesController();

  void _handleSelectedProductsChanged(Set<String> products) {
    setState(() {
      selectedProducts = products;
    });
  }

  void _handleTotalPriceChanged(double price) {
    setState(() {
      totalPrice = price;
    });
  }

  void _handleCheckout() async {
    final selectedItemsData = _cartController.getSelectedItemsData();
    if (selectedItemsData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar( 
          content: Text(
            'Please select products to checkout',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedItems = selectedItemsData['selectedItems'];
    final totalPrice = selectedItemsData['totalPrice'];

    if (selectedItems == null || totalPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred when getting product information',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((selectedItems as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one product',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CheckoutPage(
                selectedProductIds:
                    (selectedItems as List)
                        .map((item) => item['id'].toString())
                        .toSet(),
                totalAmount: (totalPrice as num).toDouble(),
                selectedItemsData: selectedItemsData,
              ),
        ),
      );

      if (result == true) {
        // Thanh toán thành công, xóa các sản phẩm đã chọn
        await _cartController.removeSelectedItems();
        // Cập nhật lại danh sách sản phẩm
        setState(() {
          selectedProducts.clear();
          this.totalPrice = 0.0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred: ${e.toString()}',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() async {
    bool isLogged = await AuthService.isLoggedIn();
    if (!isLogged) {
      Navigator.of(context).pop();
      AuthService.showLoginDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CartAppBar(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFEDECF2),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: ListView(
                    padding: EdgeInsets.only(top: 10),
                    children: [
                      CartItemSamples(
                        controller: _cartController,
                        onSelectedProductsChanged:
                            _handleSelectedProductsChanged,
                        onTotalPriceChanged: _handleTotalPriceChanged,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CartBottomNavBar(
        total: totalPrice,
        selectedProductIds: selectedProducts,
        onCheckout: _handleCheckout,
      ),
    );
  }
}
