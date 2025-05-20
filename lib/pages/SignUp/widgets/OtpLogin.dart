import 'dart:async';
import 'package:CampGo/pages/Login/LoginPage.dart';
import 'package:CampGo/pages/SignUp/SignUpPage.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpLoginPage extends StatefulWidget {
  final String email;

  const OtpLoginPage({
    Key? key, 
    required this.email,
  }) : super(key: key);

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {
  final TextEditingController otpController = TextEditingController();
  final AuthService _authService = AuthService();
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;
  bool _isOtpExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOTP(); // Tự động gửi OTP khi vào trang
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() {
          _isOtpExpired = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.sendVerifyOTP(widget.email);
      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP has been sent to your email',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Error sending OTP',
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

  Future<void> _verifyOTP() async {
    if (_isOtpExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 ký tự OTP',
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
      final response = await _authService.verifyOTP(
        widget.email,
        otpController.text,
      );

      print('Verify OTP response: $response'); // Debug log

      if (response['success'] == true) {
        if (!mounted) return;
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verification successful!',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Đợi 1 giây để người dùng thấy thông báo
        await Future.delayed(const Duration(seconds: 1));

        // Chuyển đến trang đăng nhập
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        String errorMessage = response['message'] ?? 'Mã OTP không chính xác';
        if (errorMessage.contains('expired')) {
          errorMessage = 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.';
          setState(() {
            _isOtpExpired = true;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
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

  Future<void> _resendOTP() async {
    if (_secondsRemaining > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đợi mã OTP hiện tại hết hạn trước khi yêu cầu mã mới.',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.sendVerifyOTP(widget.email);
      if (response['success'] == true) {
        if (!mounted) return;
        setState(() {
          _secondsRemaining = 60;
          _isOtpExpired = false;
          otpController.clear();
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã OTP mới đã được gửi đến email của bạn',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Error sending new OTP',
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
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
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
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 300),
                  // White form container
                  Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
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
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 35),
                            const Text(
                              'Email Verification',
                              style: TextStyle(
                                color: Color(0xFF2B2321),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 10),
                        Text(
                          'Please enter the 6-digit OTP sent to\n${widget.email}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // OTP Input
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: otpController,
                          obscureText: false,
                          enabled: !_isOtpExpired,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(3),
                            fieldHeight: 50,
                            fieldWidth: 50,
                            activeColor: _isOtpExpired 
                                ? Colors.grey 
                                : const Color.fromARGB(255, 57, 57, 57),
                            selectedColor: _isOtpExpired 
                                ? Colors.grey 
                                : const Color.fromARGB(255, 57, 57, 57),
                            inactiveColor: _isOtpExpired 
                                ? Colors.grey 
                                : const Color.fromARGB(255, 57, 57, 57),
                            activeFillColor: Colors.white,
                            selectedFillColor: Colors.white,
                            inactiveFillColor: _isOtpExpired 
                                ? Colors.grey.withOpacity(0.1) 
                                : Colors.white,
                            borderWidth: 1.5,
                          ),
                          animationDuration: const Duration(milliseconds: 300),
                          backgroundColor: const Color.fromARGB(0, 45, 44, 44),
                          enableActiveFill: true,
                          onCompleted: (v) {
                            _verifyOTP();
                          },
                          onChanged: (value) {},
                        ),

                        const SizedBox(height: 10),

                        // Timer Countdown
                        Text(
                          _secondsRemaining > 0
                              ? 'OTP will expire in $_secondsRemaining seconds'
                              : 'OTP has expired',
                          style: const TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 20),

                        // Submit button
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _isOtpExpired ? null : _verifyOTP,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(400, 55),
                                  backgroundColor: _isOtpExpired
                                      ? Colors.grey
                                      : const Color.fromARGB(255, 215, 159, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                        const SizedBox(height: 10),

                        // Resend OTP
                        TextButton(
                          onPressed: _secondsRemaining == 0 ? _resendOTP : null,
                          child: Text(
                            'Resend OTP?',
                            style: TextStyle(
                              color: _secondsRemaining == 0 
                                  ? const Color.fromARGB(255, 215, 159, 54)
                                  : Colors.grey,
                              fontWeight: _secondsRemaining == 0 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
    