import 'package:CampGo/pages/Account%20&%20Security/widgets/ChangePasswordPage.dart';
import 'package:CampGo/pages/Account%20&%20Security/widgets/EditProfilePage.dart';
import 'package:flutter/material.dart';

class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account & Security',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEDECF2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      title: 'My profile',
                      onTap: () {
                        // Handle my profile tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfilePage()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      title: 'Change password',
                      onTap: () {
                        // Handle change password tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ChangePasswordPage()),
                        );
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
