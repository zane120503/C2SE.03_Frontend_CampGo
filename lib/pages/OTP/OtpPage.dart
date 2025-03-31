import 'dart:async';
import 'package:CampGo/pages/ResetPassword/ResetPasswordPage.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({Key? key}) : super(key: key);

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  TextEditingController otpController = TextEditingController();
  int _secondsRemaining = 60;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
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
          Column(
            children: [
              const SizedBox(height: 300),
              const Spacer(),

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
      const Text(
        'Please enter the 6-digit code sent to your email',
        style: TextStyle(
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
                        activeColor: const Color.fromARGB(
                          255,
                          57,
                          57,
                          57,
                        ), // Viền đen khi đang nhập
                        selectedColor: const Color.fromARGB(
                          255,
                          57,
                          57,
                          57,
                        ), // Viền đen khi chọn
                        inactiveColor: const Color.fromARGB(
                          255,
                          57,
                          57,
                          57,
                        ), // Viền đen bình thường
                        activeFillColor: Colors.white, // Nền trắng
                        selectedFillColor: Colors.white, // Nền trắng
                        inactiveFillColor: Colors.white, // Nền trắng
                        borderWidth: 1.5, // Độ dày viền
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      backgroundColor: const Color.fromARGB(0, 45, 44, 44),
                      enableActiveFill: true,
                      onCompleted: (v) {
                        // handle completed OTP
                      },
                      onChanged: (value) {},
                    ),

                    const SizedBox(height: 10),

                    // Timer Countdown
                    Text(
                      _secondsRemaining > 0
                          ? 'OTP expires in $_secondsRemaining seconds'
                          : 'OTP expired',
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // Submit button
                    // Submit button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
    );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(400, 55),
                        backgroundColor: const Color.fromARGB(
                          255,
                          215,
                          159,
                          54,
                        ),
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
                      onPressed:
                          _secondsRemaining == 0
                              ? () {
                                setState(() {
                                  _secondsRemaining = 60;
                                  otpController.clear(); 
                                  _startTimer();
                                  // TODO: Gửi lại mã OTP tại đây
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('OTP code has been resent'),
                                    ),
                                  );
                                });
                              }
                              : null,
                      child: const Text(
                        'Resend OTP Code?',
                        style: TextStyle(
                          color: Color.fromARGB(255, 37, 39, 41),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
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
