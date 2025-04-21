import 'package:CampGo/pages/Home/HomePage.dart';
import 'package:CampGo/pages/Setting/SettingPage.dart';
import 'package:flutter/material.dart';

class UserProfileAppBar extends StatelessWidget {
  const UserProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
            child: Icon(
              Icons.arrow_back,
              size: 30,
              color: Color(0xFF2B2321),
            ),
          ),
          Spacer(),
          Text(
            "User Profile",
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2321),
            ),
          ),
          Spacer(),
          InkWell(
            onTap: () {
              // Chuyển đến trang cài đặt
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        Setting()), // Đảm bảo bạn có class SettingsPage trong settings.dart
              );
            },
            child: Icon(
              Icons.settings,
              size: 30,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
