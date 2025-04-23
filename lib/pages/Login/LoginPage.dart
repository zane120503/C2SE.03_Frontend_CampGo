import 'package:CampGo/services/auth_service.dart';
import 'package:CampGo/pages/ForgotPassword/ForgotPasswordPage.dart';
import 'package:flutter/material.dart';
import 'package:CampGo/pages/SignUp/SignUpPage.dart';
import 'package:CampGo/pages/NewProfile/NewProfilePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  bool validateInputs() {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Please Enter Email';
      });
      return false;
    }

    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      setState(() {
        _emailError = 'Invalid Email';
      });
      return false;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Please Enter Password';
      });
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
      final response = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        
        bool isProfileCompleted = response['isProfileCompleted'] ?? false;
        print('isProfileCompleted: $isProfileCompleted');

        final userData = response['data']?['user'] ?? {};
        final userName = userData['user_name'] ?? '';
        final userEmail = userData['email'] ?? '';

        print('User data from login: $userData');

        if (isProfileCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Success!',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please Update Your Personal Information',  
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewProfilePage(
                initialName: userName,
                initialEmail: userEmail,
              ),
            ),
          );
        }
      } else {
        if (!mounted) return;
        String errorMessage = 'Tài khoản hoặc mật khẩu không chính xác';
        
        // Kiểm tra status code hoặc error code từ response
        if (response['statusCode'] != null) {
          switch (response['statusCode']) {
            case 401:
              errorMessage = 'Incorrect Password';
              break;
            case 404:
              errorMessage = 'Email Does Not Exist';
              break;
            case 400:
              errorMessage = 'Invalid Email Or Password';
              break;
            default:
              errorMessage = response['message'] ?? 'Login Failed';
          }
        } else if (response['error'] != null) {
          String error = response['error'].toString().toLowerCase();
          if (error.contains('password') || error.contains('password')) {
            errorMessage = 'Incorrect Password';
          } else if (error.contains('email') || error.contains('email')) {
            errorMessage = 'Email Does Not Exist';
          } else if (error.contains('invalid') || error.contains('invalid')) {
            errorMessage = 'Invalid Email Or Password';
          }
        }

        // In ra console để debug
        print('Login error response: $response');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'An Error Occurred While Logging In';
      
      // In ra console để debug
      print('Login exception: $e');
      
      if (e.toString().contains('400')) {
        errorMessage = 'Invalid Email Or Password';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Email Does Not Exist';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server Error, Please Try Again Later';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Background Image
              SizedBox.expand(
                child: Image.asset('assets/images/StartNow.jpg', fit: BoxFit.cover),
              ),
              Container(color: Colors.black.withOpacity(0.5)),

              Column(
                children: [
                  const SizedBox(height: 200),
                  const Spacer(),
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

                        // Email TextField
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                            hintText: 'Email...',
                            labelStyle: const TextStyle(color: Colors.black87),
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
                        const SizedBox(height: 10),

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
                            errorText: _passwordError,
                            errorStyle: const TextStyle(color: Colors.red),
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
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: loginUser,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
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
                              ),
                        const SizedBox(height: 20),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
