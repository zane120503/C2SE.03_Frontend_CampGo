import 'package:CampGo/pages/Login/LoginPage.dart';
import 'package:CampGo/pages/SignUp/widgets/OtpLogin.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final ShareService _shareService = ShareService();
  bool _obscureText = true;
  bool _obscureTextConfirm = true;
  bool _isLoading = false;

  bool validateSave() {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || name.length < 3 || name.length > 50) {
      showSnackBar('The name must be between 3 and 50 characters!', Colors.red);
      return false;
    }
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      showSnackBar('Please enter a valid email!', Colors.red);
      return false;
    }
    if (password.isEmpty || password.length < 4) {
      showSnackBar('The password must be at least 4 characters!', Colors.red);
      return false;
    }
    if (password != confirmPassword) {
      showSnackBar('The passwords do not match!', Colors.red);
      return false;
    }
    return true;
  }
  
  void showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> registerUser() async {
    if (!validateSave()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      print('Register response: $response'); // Debug log

      if (response['success'] == true) {
        if (!mounted) return;
        
        // Lưu token vào ShareService
        if (response['token'] != null) {
          await ShareService.saveToken(response['token']);
          print('Token saved: ${response['token']}');
        }
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up Success!',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Đợi 1 giây để người dùng thấy thông báo
        await Future.delayed(const Duration(seconds: 1));

        // Chuyển đến trang xác thực OTP
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpLoginPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Sign up Failed',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
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
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/images/StartNow.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 73),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Padding(
                      padding: EdgeInsets.only(left: 80),
                      child: Text(
                        'Please fill the input below here',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: buildInputDecoration('Your name...'),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: buildInputDecoration('Email...'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: buildInputDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureTextConfirm,
                      decoration: buildInputDecoration('Confirm Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureTextConfirm ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureTextConfirm = !_obscureTextConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: registerUser,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(400, 55),
                              backgroundColor: const Color.fromARGB(255, 215, 159, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    const SizedBox(height: 1),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Center(
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have Account? ',
                                style: TextStyle(color: Colors.grey),
                              ),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF2B2321),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  InputDecoration buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFFBDBEBF)),
      filled: true,
      fillColor: const Color(0xFFF2F2F7).withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}