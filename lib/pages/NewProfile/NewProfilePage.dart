import 'package:CampGo/api/api.service.dart';
import 'package:CampGo/pages/Home/widgets/HomeMainNavigationBar.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class NewProfilePage extends StatefulWidget {
  final String initialName;
  final String email;

  const NewProfilePage({
    super.key,
    required this.initialName,
    required this.email,
  });

  @override
  State<NewProfilePage> createState() => _NewProfilePageState();
}

class _NewProfilePageState extends State<NewProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGender = 'male';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Chỉ điền email từ signup
    _emailController.text = widget.email;
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
        const SnackBar(content: Text('Không thể chọn ảnh. Vui lòng thử lại.')),
      );
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
    // Kiểm tra form hợp lệ
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    // Kiểm tra số điện thoại hợp lệ
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
      // Hiển thị loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang lưu thông tin...')),
      );

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = "$firstName $lastName";

      print('Sending profile data:');
      print('First Name: $firstName');
      print('Last Name: $lastName');
      print('Full Name: $fullName');
      print('Email: ${widget.email}');
      print('Phone: ${_phoneController.text}');
      print('Gender: $_selectedGender');

      // Chuẩn bị dữ liệu để gửi lên API
      final Map<String, dynamic> profileData = {
        'first_name': firstName,
        'last_name': lastName,
        'user_name': fullName,
        'email': widget.email.trim(),
        'phone_number': _phoneController.text.trim(),
        'gender': _selectedGender.toLowerCase(),
        'isProfileCompleted': true,
        'isAccountVerified': true,
        'verifyOtp': '',
        'verifyOtpExpireAt': 0,
        'resetOtp': '',
        'resetOtpExpireAt': '0',
        '__v': 0
      };

      print('Profile data to send: $profileData');

      final response = await APIService.updateProfile(
        name: fullName,
        email: widget.email.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender.toLowerCase(),
        profileImage: _imageFile,
        isProfileCompleted: true,
      );

      print('Update profile response: $response');

      if (response['success'] == true) {
        if (!mounted) return;
        
        // Lưu thông tin vào local storage với đầy đủ dữ liệu
        await AuthService.updateUserProfile(profileData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
        
        // Chuyển đến trang HomePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeMainNavigationBar()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Cập nhật thông tin thất bại')),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
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
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
