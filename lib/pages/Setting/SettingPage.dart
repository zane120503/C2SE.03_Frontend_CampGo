import 'package:CampGo/pages/Account%20&%20Security/AccountSecurityPage.dart';
import 'package:CampGo/pages/Address/AddressPage.dart';
import 'package:CampGo/pages/Card%20Account/CreditCardPage.dart';
import 'package:CampGo/pages/Language/LanguagePage.dart';
import 'package:CampGo/pages/Login/LoginPage.dart';
import 'package:CampGo/pages/NotificationSettings/NotificationSettingsPage.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:flutter/material.dart';

class Setting extends StatelessWidget {
  const Setting({Key? key}) : super(key: key);

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Log Out'),
              onPressed: () async {
                try {
                  await AuthService.logout(context);
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Setting',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: ListView(
        children: [
          _buildSectionTitle('My Account'),
          _buildListTile(
            context: context,
            title: 'Account & Security',
            icon: Icons.security,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountSecurityPage()),
            ),
          ),
          _buildListTile(
            context: context,
            title: 'Address',
            icon: Icons.location_on,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddressPage()),
            ),
          ),
          _buildListTile(
            context: context,
            title: 'Credit Card',
            icon: Icons.account_balance,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreditCardPage()),
            ),
          ),

          _buildSectionTitle('Setting'),
          _buildListTile(
            context: context,
            title: 'Notification Settings',
            icon: Icons.notifications,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
            ),
          ),
          _buildListTile(
            context: context,
            title: 'Language',
            icon: Icons.language,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LanguagePage()),
            ),
          ),

          _buildSectionTitle('Support Center'),
          _buildListTile(
            context: context,
            title: 'Help Center',
            icon: Icons.help,
            onTap: () {
              // TODO: Implement help center
            },
          ),
          _buildListTile(
            context: context,
            title: 'Community Standards',
            icon: Icons.people,
            onTap: () {
              // TODO: Implement community standards
            },
          ),
          _buildListTile(
            context: context,
            title: 'Satisfaction Survey',
            icon: Icons.star,
            onTap: () {
              // TODO: Implement satisfaction survey
            },
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
