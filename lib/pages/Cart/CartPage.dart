import 'package:flutter/material.dart';
import 'package:CampGo/pages/Cart/widgets/CartAppBar.dart';
import 'package:CampGo/pages/Cart/widgets/CartBottomNavBar.dart';
import 'package:CampGo/pages/Cart/widgets/CartItemSamples.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/pages/Checkout/CheckOutPage.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  double _totalAmount = 0.0;
  Set<String> _selectedProductIds = {};

  void _handleCheckout() {
    if (_totalAmount > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPage(
            selectedProductIds: _selectedProductIds,
            totalAmount: _totalAmount,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn sản phẩm trước khi thanh toán'),
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
                  child: ListView(
                    padding: EdgeInsets.only(top: 10),
                    children: [
                      CartItemSamples(
                        onTotalPriceChanged: (double totalPrice) {
                          setState(() {
                            _totalAmount = totalPrice;
                          });
                        },
                        onSelectedItemsChanged: (Set<String> selectedIds) {
                          setState(() {
                            _selectedProductIds = selectedIds;
                          });
                        },
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
        total: _totalAmount,
        onCheckout: _handleCheckout,
      ),
    );
  }
}
