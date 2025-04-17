import 'package:flutter/material.dart';
import 'package:CampGo/services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isFormValid = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      // Reset all error messages
      _oldPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;

      // Validate old password
      if (oldPassword.isEmpty) {
        _oldPasswordError = 'Please enter your old password';
      } else if (oldPassword.length < 6) {
        _oldPasswordError = 'Old password must be at least 6 characters';
      }

      // Validate new password
      if (newPassword.isEmpty) {
        _newPasswordError = 'Please enter your new password';
      } else if (newPassword.length < 6) {
        _newPasswordError = 'New password must be at least 6 characters';
      }

      // Validate confirm password
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Please confirm your new password';
      } else if (confirmPassword != newPassword) {
        _confirmPasswordError = 'Confirm password does not match';
      }

      _isFormValid = oldPassword.length >= 6 &&
          newPassword.length >= 6 &&
          newPassword == confirmPassword;
    });
  }

  Future<void> _changePassword() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.changePassword(
        currentPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Password changed successfully',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'];
          if (result['message'].toString().toLowerCase().contains('current password')) {
            _oldPasswordError = 'Old password is incorrect';
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
      });
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _isFormValid ? _changePassword : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: _isFormValid ? Colors.pink : Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEDECF2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: _oldPasswordController,
                      hintText: 'Enter old password',
                      isVisible: _oldPasswordVisible,
                      onVisibilityChanged: (value) {
                        setState(() => _oldPasswordVisible = value);
                      },
                      showDivider: true,
                      errorText: _oldPasswordError,
                    ),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      hintText: 'Enter password',
                      isVisible: _newPasswordVisible,
                      onVisibilityChanged: (value) {
                        setState(() => _newPasswordVisible = value);
                      },
                      showDivider: true,
                      errorText: _newPasswordError,
                    ),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm password',
                      isVisible: _confirmPasswordVisible,
                      onVisibilityChanged: (value) {
                        setState(() => _confirmPasswordVisible = value);
                      },
                      errorText: _confirmPasswordError,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required Function(bool) onVisibilityChanged,
    bool showDivider = false,
    String? errorText,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          obscureText: !isVisible,
          onChanged: (_) => _validateForm(),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
              ),
              onPressed: () => onVisibilityChanged(!isVisible),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[200],
          ),
      ],
    );
  }
}
