import 'package:CampGo/pages/Favorite/widgets/FavoriteAppBar.dart';
import 'package:CampGo/pages/Favorite/widgets/FavoriteItemSamples.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:flutter/material.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  _FavoritePageState createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    AuthService.checkProtectedRoute(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            FavoriteAppBar(), // Đảm bảo FavoriteAppBar không null
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEDECF2),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.only(top: 10),
                  children: const [
                    FavoriteItemSamples(),
                    // Thêm SizedBox để tạo khoảng trống ở cuối danh sách
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
