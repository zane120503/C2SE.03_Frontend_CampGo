import 'package:CampGo/pages/Home/HomePage.dart';
import 'package:flutter/material.dart';

class FavoriteAppBar extends StatefulWidget {
  const FavoriteAppBar({super.key});

  @override
  _FavoriteAppBarState createState() => _FavoriteAppBarState();
}

class _FavoriteAppBarState extends State<FavoriteAppBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Text(
            "Favorite ",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2321),
            ),
          ),
          Spacer(), // Tạo khoảng cách giữa tiêu đề và icon trái tim
          Icon(
            Icons.favorite,
            size: 30,
            color: Colors.red, // Đặt màu cho biểu tượng trái tim
          ),
        ],
      ),
    );
  }
}
