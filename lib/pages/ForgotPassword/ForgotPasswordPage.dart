import 'package:CampGo/pages/OTP/OtpPage.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

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

              const Spacer(), // Push form down
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
                    // Title
                    const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Color(0xFF2B2321),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Text(
                      'Enter your email to reset password',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    // Email TextField
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtpPage(
                              email: _emailController.text.trim(),
                            ),
                          ),
                        );
                        // Quay về LoginPage sau khi gửi
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
                        'Send OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Already have account -> Log in text
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Quay lại LoginPage
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
                    const SizedBox(height: 20),
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
