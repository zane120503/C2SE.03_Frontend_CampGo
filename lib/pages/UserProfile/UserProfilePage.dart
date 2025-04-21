import 'package:CampGo/pages/UserProfile/widgets/UserProfileAppBar.dart';
import 'package:CampGo/pages/UserProfile/widgets/UserProfileItemSamples.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            UserProfileAppBar(), // Đảm bảo UserProfileAppBar không null
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
                    UserProfileItemSamples(),
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
