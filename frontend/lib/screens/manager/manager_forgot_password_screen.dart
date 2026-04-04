import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manager_otp_screen.dart';

class ManagerForgotPasswordScreen extends StatefulWidget {
  const ManagerForgotPasswordScreen({super.key});

  @override
  State<ManagerForgotPasswordScreen> createState() =>
      _ManagerForgotPasswordScreenState();
}

class _ManagerForgotPasswordScreenState
    extends State<ManagerForgotPasswordScreen> {
  final _managerIdController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _email = '';
  final String baseUrl = 'http://10.0.2.2:8080';

  Future<void> _sendOTP() async {
    if (_managerIdController.text.isEmpty) {
      _showError('Please enter your Manager ID');
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showError('Please enter new password');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/manager/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'managerId': _managerIdController.text.trim(),
        }),
      );

      final result = response.body;

      if (result.startsWith('OTP_SENT')) {
        final email = result.split(':')[1];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ManagerOTPScreen(
              managerId:
              _managerIdController.text.trim(),
              email: email,
              purpose: 'RESET_PASSWORD',
              newPassword: _newPasswordController.text,
            ),
          ),
        );
      } else if (result == 'NOT_FOUND') {
        _showError('No user found with this Manager ID');
      } else {
        _showError('Failed to send OTP. Try again.');
      }
    } catch (e) {
      _showError('Connection error.');
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white),
                          onPressed: () =>
                              Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                        Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Enter your ID and new password',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _managerIdController,
                      decoration: InputDecoration(
                        labelText: 'Manager ID',
                        hintText: 'Enter your Manager ID',
                        prefixIcon: const Icon(
                            Icons.badge_rounded,
                            color: Color(0xFF0D47A1)),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Min 6 characters',
                        prefixIcon: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFF0D47A1)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons
                                .visibility_off_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() =>
                          _obscurePassword =
                          !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : _sendOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
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
}