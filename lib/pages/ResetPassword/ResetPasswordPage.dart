import 'package:flutter/material.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/pages/Login/LoginPage.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscureText = true;
  bool _obscureTextConfirm = true;
  bool _isLoading = false;

  bool validatePassword() {
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || password.length < 4) {
      showSnackBar('Mật khẩu phải có ít nhất 4 ký tự!', Colors.red);
      return false;
    }
    if (password != confirmPassword) {
      showSnackBar('Mật khẩu không khớp!', Colors.red);
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

  Future<void> resetPassword() async {
    if (!mounted) return;
    
    if (!validatePassword()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.resetPassword(
        widget.email,
        widget.otp,
        _passwordController.text,
      );

      print('Reset password response: $response'); // Debug log

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt lại mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Đợi 1 giây để người dùng thấy thông báo
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Đặt lại mật khẩu thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Reset password error: $e'); // Debug log
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
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
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/StartNow.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),

          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 20),

                    // White Form Container
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
                        children: [
                          // Back Button + Title
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(width: 50),
                              const Text(
                                'Đặt lại mật khẩu',
                                style: TextStyle(
                                  color: Color(0xFF2B2321),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // New Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu mới',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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

                          // Confirm New Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureTextConfirm,
                            decoration: InputDecoration(
                              labelText: 'Xác nhận mật khẩu mới',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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

                          const SizedBox(height: 30),

                          // Reset Password Button
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: resetPassword,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(400, 55),
                                    backgroundColor: const Color.fromARGB(255, 215, 159, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Đặt lại mật khẩu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
