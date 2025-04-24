import 'package:flutter/material.dart';
import 'package:CampGo/pages/CheckOut/CheckOutPage.dart';

class CartBottomNavBar extends StatelessWidget {
  final double total;
  final Set<String> selectedProductIds;
  final VoidCallback? onCheckout;
  
  const CartBottomNavBar({
    Key? key, 
    required this.total,
    required this.selectedProductIds,
    this.onCheckout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2321),
                ),
              ),
              Text(
                ' ${total.toStringAsFixed(2)}đ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2321),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: selectedProductIds.isEmpty ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedProductIds.isEmpty 
                  ? Colors.grey 
                  : Color(0xFF2B2321),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Check Out',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}