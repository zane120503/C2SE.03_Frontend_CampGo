import 'package:CampGo/pages/Home/widgets/HomeMainNavigationBar.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:CampGo/api/api.service.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/services/share_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGender = 'male';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kiểm tra token trước
      String? token = await ShareService.getToken();
      print('Token for loading profile: $token');

      if (token == null || token.isEmpty) {
        // Thử lấy token từ AuthService
        token = await AuthService().getToken();
        print('Token from AuthService: $token');
        
        if (token == null || token.isEmpty) {
          throw Exception('Vui lòng đăng nhập lại');
        }
        
        // Lưu token vào ShareService nếu chưa có
        await ShareService.saveToken(token);
      }

      bool isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Vui lòng đăng nhập để xem thông tin');
      }

      // Lấy thông tin từ local storage trước
      final userDetails = await ShareService.getUserDetails();
      final userInfo = await ShareService.getUserInfo();
      
      if (userDetails != null) {
        print('Loading user details from local storage: $userDetails');
        setState(() {
          _firstNameController.text = userDetails['first_name'] ?? '';
          _lastNameController.text = userDetails['last_name'] ?? '';
          _phoneController.text = userDetails['phone_number'] ?? '';
          _selectedGender = userDetails['gender'] ?? 'male';
          _emailController.text = userInfo?['email'] ?? '';
        });
      }

      // Gọi API để lấy thông tin mới nhất
      final response = await APIService.getUserProfile();
      print('User Profile Response: $response');

      if (response['success'] == true && response['userData'] != null) {
        final userData = response['userData'];
        
        // Cập nhật UI với dữ liệu mới nhất
        setState(() {
          _firstNameController.text = userData['first_name'] ?? _firstNameController.text;
          _lastNameController.text = userData['last_name'] ?? _lastNameController.text;
          _phoneController.text = userData['phone_number'] ?? _phoneController.text;
          _selectedGender = (userData['gender'] ?? _selectedGender).toLowerCase();
          _emailController.text = userData['email'] ?? _emailController.text;
          
          // Xử lý hiển thị ảnh profile nếu có
          if (userData['profileImage'] != null && 
              userData['profileImage'] is Map && 
              userData['profileImage']['url'] != null) {
            print('Profile image URL: ${userData['profileImage']['url']}');
            // TODO: Hiển thị ảnh từ URL
          }
        });

        // Lưu thông tin mới vào local storage
        await ShareService.saveUserDetails({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'phone_number': _phoneController.text,
          'gender': _selectedGender,
        });

        // Cập nhật thông tin user
        await ShareService.saveUserInfo(
          userId: userData['_id'] ?? userInfo?['userId'] ?? '',
          email: userData['email'] ?? userInfo?['email'] ?? '',
          userName: '${_firstNameController.text} ${_lastNameController.text}',
          isProfileCompleted: true
        );
      } else {
        throw Exception('Không thể lấy thông tin người dùng');
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get isFormValid {
    return _firstNameController.text.isNotEmpty &&
           _lastNameController.text.isNotEmpty &&
           _emailController.text.isNotEmpty &&
           _phoneController.text.isNotEmpty &&
           _selectedGender.isNotEmpty;
  }

  Future<void> _saveProfile() async {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại phải có 10 chữ số')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = "$firstName $lastName";

      // Kiểm tra token trước khi gọi API
      String? token = await ShareService.getToken();
      print('Token before update profile: $token');

      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      // Cập nhật profile
      final response = await APIService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: _phoneController.text.trim(),
        gender: _selectedGender.toLowerCase(),
        profileImage: _imageFile,
      );

      print('Update profile response: $response');

      if (response['success'] == true) {
        if (!mounted) return;

        // Kiểm tra và lưu thông tin từ response
        final userData = response['data'];
        if (userData == null) {
          throw Exception('Không nhận được dữ liệu từ server');
        }

        // Lưu thông tin vào local storage
        await ShareService.saveUserInfo(
          userId: userData['_id']?.toString() ?? '',
          email: userData['email']?.toString() ?? _emailController.text.trim(),
          userName: fullName,
          isProfileCompleted: true
        );

        // Lưu thêm thông tin chi tiết
        await ShareService.saveUserDetails({
          'first_name': userData['first_name']?.toString() ?? '',
          'last_name': userData['last_name']?.toString() ?? '',
          'phone_number': userData['phone_number']?.toString() ?? '',
          'gender': userData['gender']?.toString() ?? 'male',
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Chuyển đến trang HomePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeMainNavigationBar()),
          (route) => false,
        );
      } else {
        throw Exception(response['message'] ?? 'Cập nhật thông tin thất bại');
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot pick image. Please try again.',
            textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 0, 0),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEDECF2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // Avatar section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _imageFile == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD79F36),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Form fields
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              label: 'First Name',
                              controller: _firstNameController,
                              showDivider: true,
                            ),
                            _buildTextField(
                              label: 'Last Name',
                              controller: _lastNameController,
                              showDivider: true,
                            ),
                            _buildTextField(
                              label: 'Email',
                              controller: _emailController,
                              showDivider: true,
                              keyboardType: TextInputType.emailAddress,
                              enabled: false,
                            ),
                            _buildTextField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              showDivider: true,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildGenderSelector(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool showDivider = false,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              label: Text(label),
              border: InputBorder.none,
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            enabled: enabled,
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEEEE),
          ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildGenderOption('male', 'Male'),
              const SizedBox(width: 16),
              _buildGenderOption('female', 'Female'),
              const SizedBox(width: 16),
              _buildGenderOption('other', 'Other'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD79F36) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFFD79F36) : Colors.grey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
