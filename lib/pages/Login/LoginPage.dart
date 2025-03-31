import 'dart:convert';
import 'package:CampGo/pages/ForgotPassword/ForgotPasswordPage.dart';
import 'package:CampGo/pages/SignUp/SignUpPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  bool validateInputs() {
    if (_nameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return false;
    }
    return true;
  }

  Future<void> loginUser() async {
    if (!validateInputs()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final String response = await rootBundle.loadString('assets/data/Login.json');
      final data = await json.decode(response);

      String username = _nameController.text.trim();
      String password = _passwordController.text;

      bool isSuccess = false;
      for (var user in data['users']) {
        if (user['username'] == username && user['password'] == password) {
          isSuccess = true;
          break;
        }
      }

      if (isSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reading login data: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration buildInputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.withOpacity(0.2),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
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
    const SizedBox(height: 280), // Có thể bỏ bớt nếu không cần

    const Spacer(), // Đẩy xuống cuối

    // FORM trắng
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
          // Đưa chữ Login vào đây
          const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF2B2321),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Please fill the input below here',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Username TextField
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.withOpacity(0.1),
              hintText: 'User Name',
              labelStyle: const TextStyle(color: Colors.black87),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Password TextField
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.withOpacity(0.1),
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          // Forgot Password Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ForgotPasswordPage()),
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFF2B2321),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: loginUser,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(400, 55),
                    backgroundColor: const Color.fromARGB(255, 215, 159, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
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
                  builder: (context) => const SignUpPage(),
                ),
              );
            },
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Create Account? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextSpan(
                    text: 'Sign up',
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
)

        ],
      ),
    );
  }
}
