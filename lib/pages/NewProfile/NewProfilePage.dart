import 'package:CampGo/api/api.service.dart';
import 'package:CampGo/pages/Home/widgets/HomeMainNavigationBar.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:CampGo/services/share_service.dart';

class NewProfilePage extends StatefulWidget {
  final String initialName;
  final String initialEmail;

  const NewProfilePage({
    super.key,
    this.initialName = '',
    this.initialEmail = '',
  });

  @override
  State<NewProfilePage> createState() => _NewProfilePageState();
}

class _NewProfilePageState extends State<NewProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedGender = 'male';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo email từ initialEmail
    _emailController.text = widget.initialEmail;
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
        const SnackBar(content: Text('Unable to select image. Please try again.',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get isFormValid {
    return _firstNameController.text.isNotEmpty &&
           _lastNameController.text.isNotEmpty &&
           _phoneController.text.isNotEmpty &&
           _selectedGender.isNotEmpty;
  }

  Future<void> _saveProfile() async {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all information',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must be 10 digits',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
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
        // Thử lấy token từ AuthService
        token = await AuthService().getToken();
        print('Token from AuthService: $token');
        
        if (token == null || token.isEmpty) {
          throw Exception('Please login again');
        }
        
        // Lưu token vào ShareService nếu chưa có
        await ShareService.saveToken(token);
      }

      // Cập nhật profile với isProfileCompleted = true
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
          throw Exception('Unable to get data from server');
        }

        // Lưu thông tin vào local storage với isProfileCompleted = true
        await ShareService.saveUserInfo(
          userId: userData['_id']?.toString() ?? '',
          email: userData['email']?.toString() ?? _emailController.text.trim(),
          userName: fullName,
          isProfileCompleted: true,
        );

        // Lưu thêm thông tin chi tiết vào local storage
        await ShareService.saveUserDetails({
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': _phoneController.text.trim(),
          'gender': _selectedGender.toLowerCase(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update information successfully',
            textAlign: TextAlign.center,
            ),
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
        throw Exception(response['message'] ?? 'Update information failed');
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}',
            textAlign: TextAlign.center,
            ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFD79F36),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
