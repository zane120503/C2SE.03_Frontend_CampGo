import 'package:CampGo/pages/Account%20&%20Security/AccountSecurityPage.dart';
import 'package:CampGo/pages/Address/AddressPage.dart';
import 'package:CampGo/pages/Card%20Account/CreditCardPage.dart';
import 'package:CampGo/pages/Login/LoginPage.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/pages/Campsite%20Owner/CampsiteOwnerPage.dart';

class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool? isCampsiteOwner;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final profile = await APIService.getUserProfile();
    print('Get profile API response body: ${profile}'); // debug log
    setState(() {
      // Lấy isCampsiteOwner từ userData trong response
      isCampsiteOwner = profile['userData']?['isCampsiteOwner'] ?? false;
      _loading = false;
    });
  }

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
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: iconColor ?? textColor),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
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
                _buildSectionTitle('Campsite Owner'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(
                              'Confirm',
                              textAlign: TextAlign.center,
                            ),
                            content: const Text(
                              'Do you want to become a Campsite Owner?',
                              textAlign: TextAlign.center,
                            ),
                            actions: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: const Text(
                                      'No',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text(
                                      'Yes',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                      if (result == true) {
                        final apiResult = await APIService.requestCampsiteOwner();
                        if (apiResult['success'] == true) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                contentPadding: EdgeInsets.all(16.0),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 80.0,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Campsite owner request has been sent successfully',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'We will contact you as soon as possible',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 30),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(apiResult['message'] ?? 'Request failed')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.map_outlined, color: Colors.white),
                        ),
                        SizedBox(width: 15),
                        Text(
                          'Campsite Owner Account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildListTile(
                  context: context,
                  title: 'Campsite Owner Management',
                  icon: Icons.manage_accounts,
                  onTap: isCampsiteOwner == true
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CampsiteOwnerPage()),
                        )
                      : () {},
                  iconColor: isCampsiteOwner == true ? null : Colors.grey,
                  textColor: isCampsiteOwner == true ? null : Colors.grey,
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: double.infinity,
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
            ),
          ),
        ],
      ),
    );
  }
}
