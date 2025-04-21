import 'dart:async';
import 'package:CampGo/pages/ResetPassword/ResetPasswordPage.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController otpController = TextEditingController();
  final AuthService _authService = AuthService();
  int _secondsRemaining = 60;
  late final Timer _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOTP(); // Tự động gửi OTP khi vào trang
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
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
      final response = await _authService.sendResetOTP(widget.email);
      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã OTP đã được gửi đến email của bạn'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Lỗi gửi mã OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _verifyOTP() async {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 số OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.verifyResetOTP(
        widget.email,
        otpController.text,
      );

      print('Verify Reset OTP response: $response'); // Debug log

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
            content: Text('Xác thực OTP thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Đợi 1 giây để người dùng thấy thông báo
        await Future.delayed(const Duration(seconds: 1));

        // Chuyển đến trang đặt lại mật khẩu
        if (!mounted) return;
        final otp = otpController.text; // Lưu giá trị OTP trước khi dispose
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(
              email: widget.email,
              otp: otp,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Mã OTP không đúng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.sendResetOTP(widget.email);
      if (response['success'] == true) {
        if (!mounted) return;
        setState(() {
          _secondsRemaining = 60;
          otpController.clear();
          _startTimer();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã OTP mới đã được gửi đến email của bạn'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Lỗi gửi lại mã OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
  void dispose() {
    _timer.cancel();
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
                    
                    // White form container
                    Container(
                      padding: const EdgeInsets.all(20),
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
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(width: 80),
                              const Text(
                                'Enter OTP',
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
                            'Vui lòng nhập mã OTP 6 số đã được gửi đến\n${widget.email}',
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
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(3),
                              fieldHeight: 50,
                              fieldWidth: 50,
                              activeColor: const Color.fromARGB(255, 57, 57, 57),
                              selectedColor: const Color.fromARGB(255, 57, 57, 57),
                              inactiveColor: const Color.fromARGB(255, 57, 57, 57),
                              activeFillColor: Colors.white,
                              selectedFillColor: Colors.white,
                              inactiveFillColor: Colors.white,
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
                                ? 'Mã OTP sẽ hết hạn sau $_secondsRemaining giây'
                                : 'Mã OTP đã hết hạn',
                            style: const TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 20),

                          // Submit button
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _verifyOTP,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(400, 55),
                                    backgroundColor: const Color.fromARGB(255, 215, 159, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Xác nhận OTP',
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
                            child: const Text(
                              'Gửi lại mã OTP?',
                              style: TextStyle(
                                color: Color.fromARGB(255, 37, 39, 41),
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
}
