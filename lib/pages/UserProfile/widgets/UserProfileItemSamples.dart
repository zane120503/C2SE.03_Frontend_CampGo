import 'package:CampGo/models/user_model.dart';
import 'package:CampGo/pages/Evaluate/EvaluatePage.dart';
import 'package:CampGo/pages/WaitForConfirmation/WaitForConfirmationPage.dart';
import 'package:CampGo/pages/WaitingForDelivery/WaitingForDeliveryPage.dart';
import 'package:CampGo/services/data_service.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/services/share_service.dart';
import 'package:flutter/material.dart';

class UserProfileItemSamples extends StatefulWidget {
  const UserProfileItemSamples({super.key});

  @override
  _UserProfileItemSamplesState createState() => _UserProfileItemSamplesState();
}

class _UserProfileItemSamplesState extends State<UserProfileItemSamples> {
  final DataService dataService = DataService();
  UserProfile? _userProfileScreen;

  int _pendingCount = 0;
  int _shippingCount = 0;
  int _evaluateCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadOrderCounts();
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

  Future<void> _loadOrderCounts() async {
    try {
      final response = await APIService.getOrders();
      if (response != null && response['success'] == true) {
        final List<dynamic> orders = response['data'] ?? [];
        final deliveredOrders = orders.where((order) =>
          order['delivery_status'] == 'Delivered' &&
          order['payment_status'] == 'Completed'
        ).toList();

        int notReviewedCount = 0;
        final userInfo = await ShareService.getUserInfo();
        final userId = userInfo?['userId'];

        for (var order in deliveredOrders) {
          for (var product in order['products']) {
            final productId = product['product']['_id'];
            final reviewRes = await APIService.getProductReviews(productId);
            final reviews = reviewRes['data']['reviews'] as List;
            final hasReviewed = reviews.any((review) => review['user_id'] == userId);
            if (!hasReviewed) {
              notReviewedCount++;
            }
          }
        }

        setState(() {
          _pendingCount = orders.where((order) => order['delivery_status'] == 'Pending').length;
          _shippingCount = orders.where((order) => order['waiting_confirmation'] == true && order['delivery_status'] == 'Shipping').length;
          _evaluateCount = notReviewedCount;
        });
      }
    } catch (e) {
      print('Error loading order counts: $e');
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
                  _buildProfileImage(),
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
                    Icons.check_box, "Wait for confirmation", const Color.fromARGB(255, 10, 160, 230), context, _onWaitForConfirmation, _pendingCount),
                _buildOrderStatusButton(
                    Icons.local_shipping, "Waiting for delivery", const Color.fromARGB(255, 57, 42, 224), context, _onWaitingForDelivery, _shippingCount),
                _buildOrderStatusButton(
                    Icons.star, "Evaluate", const Color.fromARGB(255, 249, 167, 2), context, _onEvaluate, _evaluateCount),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_userProfileScreen?.profileImage != null && 
        _userProfileScreen!.profileImage!['url'] != null) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(_userProfileScreen!.profileImage!['url']),
      );
    }
    return const CircleAvatar(
      radius: 30,
      child: Icon(Icons.person, size: 30),
    );
  } 

  Widget _buildOrderStatusButton(
      IconData icon, String label, Color color, BuildContext context, Function(BuildContext) onTap, int count) {
    return InkWell(
      onTap: () => onTap(context),
      child: Column(
        children: [
          Stack(
            children: [
              Icon(icon, size: 40, color: color),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -7,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 5),
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
