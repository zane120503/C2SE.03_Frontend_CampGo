import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool inAppNotifications = false;
  bool emailNotifications = false;
  bool smsNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification settings',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Thông báo trong ứng dụng',
                    inAppNotifications,
                    (value) {
                      setState(() {
                        inAppNotifications = value;
                      });
                    },
                    horizontalPadding: 24,
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    'Thông báo Gmail',
                    emailNotifications,
                    (value) {
                      setState(() {
                        emailNotifications = value;
                      });
                    },
                    horizontalPadding: 24,
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    'SMS Notifications',
                    smsNotifications,
                    (value) {
                      setState(() {
                        smsNotifications = value;
                      });
                    },
                    horizontalPadding: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, bool value, ValueChanged<bool> onChanged,
      {double horizontalPadding = 16}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
