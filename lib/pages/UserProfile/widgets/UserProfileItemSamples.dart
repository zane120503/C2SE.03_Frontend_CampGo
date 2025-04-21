import 'package:CampGo/models/user_model.dart';
import 'package:CampGo/pages/Evaluate/EvaluatePage.dart';
import 'package:CampGo/pages/WaitForConfirmation/WaitForConfirmationPage.dart';
import 'package:CampGo/pages/WaitingForDelivery/WaitingForDeliveryPage.dart';
import 'package:CampGo/services/data_service.dart';
import 'package:flutter/material.dart';

class UserProfileItemSamples extends StatefulWidget {
  const UserProfileItemSamples({super.key});

  @override
  _UserProfileItemSamplesState createState() => _UserProfileItemSamplesState();
}

class _UserProfileItemSamplesState extends State<UserProfileItemSamples> {
  final DataService dataService = DataService();
  UserProfile? _userProfileScreen;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    UserProfile? userProfile = await dataService.getUserProfile();
    print("This is user profile: $userProfile"); // Debug thông tin user profile
    if (userProfile != null) {
      setState(() {
        _userProfileScreen = userProfile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: _userProfileScreen?.profileImage?.isNotEmpty == true
                        ? NetworkImage(_userProfileScreen?.profileImage ?? '')
                        : null,
                    child: _userProfileScreen?.profileImage?.isEmpty == true
                        ? Icon(Icons.person, size: 40, color: Colors.black)
                        : null,
                  ),
                  SizedBox(width: 16),
                  Text(
                    _userProfileScreen?.fullName ?? 'User',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Divider(thickness: 1),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(width: 8),
                    Text(
                      "Purchase Order",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2B2321),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOrderStatusButton(
                    Icons.check_box, "Wait for confirmation", Colors.black, context, _onWaitForConfirmation),
                _buildOrderStatusButton(
                    Icons.local_shipping, "Waiting for delivery", Colors.black, context, _onWaitingForDelivery),
                _buildOrderStatusButton(
                    Icons.star, "Evaluate", Colors.black, context, _onEvaluate),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusButton(
      IconData icon, String label, Color color, BuildContext context, Function(BuildContext) onTap) {
    return InkWell(
      onTap: () => onTap(context),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _onWaitForConfirmation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WaitForConfirmationPage()),
    );
  }

  void _onWaitingForDelivery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WaitingForDeliveryPage()),
    );
  }

  void _onEvaluate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EvaluatePage()),
    );
  }
}
