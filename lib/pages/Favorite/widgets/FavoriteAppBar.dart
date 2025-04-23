import 'package:CampGo/pages/Home/HomePage.dart';
import 'package:flutter/material.dart';

class FavoriteAppBar extends StatefulWidget implements PreferredSizeWidget {
  const FavoriteAppBar({super.key});

  @override
  _FavoriteAppBarState createState() => _FavoriteAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _FavoriteAppBarState extends State<FavoriteAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Favorite",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2321),
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }
}
