import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class HomeNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const HomeNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      
      onTap: onTap,
      height: 70,
      color: const Color(0xFF2B2321),
      index: selectedIndex,
      items: const [
        Icon(
          Icons.home,
          size: 30,
          color: Colors.white,
        ),
        Icon(
          Icons.shopping_cart,
          size: 30,
          color: Colors.white,
        ),
        Icon(
          Icons.map_outlined,
          size: 30,
          color: Colors.white,
        ),
        Icon(
          Icons.favorite,
          size: 30,
          color: Colors.white,
        ),
        Icon(
          Icons.person,
          size: 30,
          color: Colors.white,
        ),
      ],
    );
  }
}
