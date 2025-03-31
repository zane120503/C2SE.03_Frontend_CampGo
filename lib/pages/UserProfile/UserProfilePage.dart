import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Trang hồ sơ người dùng'),
      ),
    );
  }
}
