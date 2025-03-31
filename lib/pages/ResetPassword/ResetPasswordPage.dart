import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

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

          Column(
            children: [
              const SizedBox(height: 300),
              const Spacer(),

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
                          'Reset Password',
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
                      controller: newPasswordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm New Password
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isConfirmPasswordVisible = !isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Reset Password Button
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Add password reset logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(400, 55),
                        backgroundColor: const Color.fromARGB(255, 215, 159, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Reset Password',
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
        ],
      ),
    );
  }
}
