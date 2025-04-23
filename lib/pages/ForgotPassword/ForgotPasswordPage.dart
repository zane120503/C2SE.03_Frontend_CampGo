import 'package:CampGo/pages/OTP/OtpPage.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _isButtonEnabled = false;

  bool _isValidEmail(String email) {
    // Kiểm tra email không được trống
    if (email.isEmpty) {
      _emailError = 'Please enter email';
      return false;
    }

    // Kiểm tra định dạng email cơ bản
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      _emailError = 'Invalid Email';
      return false;
    }

    // Kiểm tra độ dài tối đa của email
    if (email.length > 254) {
      _emailError = 'Email is too long';
      return false;
    }

    // Kiểm tra phần tên miền
    final parts = email.split('@');
    if (parts.length != 2) {
      _emailError = 'Invalid Email';
      return false;
    }

    final domain = parts[1];
    if (domain.length < 3) {
      _emailError = 'Invalid Email';
      return false;
    }

    // Kiểm tra không có khoảng trắng
    if (email.contains(' ')) {
      _emailError = 'Email cannot contain spaces';
      return false;
    }

    // Kiểm tra không có ký tự đặc biệt không hợp lệ
    if (email.contains('..') || email.contains('@.') || email.contains('.@')) {
      _emailError = 'Invalid Email';
      return false;
    }

    _emailError = null;
    return true;
  }

  void _validateEmail(String value) {
    setState(() {
      _isButtonEnabled = _isValidEmail(value);
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      _validateEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset('assets/images/StartNow.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.5)),

          Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row chứa nút back + title
                    Row(
                      children: [
                        const SizedBox(width: 70),
                        const Text(
                          'Forgot Password',
                          style: TextStyle(
                            color: Color(0xFF2B2321),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Enter your email to reset password',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    // Email TextField
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        hintText: 'Email',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _emailError,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isButtonEnabled
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtpPage(
                                      email: _emailController.text.trim(),
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: _isButtonEnabled
                              ? const Color.fromARGB(255, 215, 159, 54)
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Send OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Already have account -> Log in text
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have Account? ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                color: Color(0xFF2B2321),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
