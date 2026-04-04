import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manager_otp_screen.dart';

class ManagerRegisterScreen extends StatefulWidget {
  const ManagerRegisterScreen({super.key});

  @override
  State<ManagerRegisterScreen> createState() =>
      _ManagerRegisterScreenState();
}

class _ManagerRegisterScreenState
    extends State<ManagerRegisterScreen> {
  final _managerIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  Future<void> _register() async {
    if (_managerIdController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _companyController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/manager/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'managerId': _managerIdController.text.trim(),
          'name': _nameController.text.trim(),
          'companyName': _companyController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final result = response.body;

      if (result == 'OTP_SENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ManagerOTPScreen(
              managerId:
              _managerIdController.text.trim(),
              email: _emailController.text.trim(),
              purpose: 'REGISTRATION',
            ),
          ),
        );
      } else if (result == 'ID_EXISTS') {
        _showError('Manager ID already exists');
      } else if (result == 'EMAIL_EXISTS') {
        _showError('Email already registered');
      } else {
        _showError('Registration failed. Try again.');
      }
    } catch (e) {
      _showError('Connection error. Is backend running?');
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
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Register as a Manager',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildField(
                      _managerIdController,
                      'Manager ID',
                      'Create a unique ID',
                      Icons.badge_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _nameController,
                      'Full Name',
                      'Your full name',
                      Icons.person_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _companyController,
                      'Company Name',
                      'Your company name',
                      Icons.business_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _emailController,
                      'Email',
                      'OTP will be sent here',
                      Icons.email_rounded,
                      isEmail: true,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
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

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : _register,
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                              color: Colors.grey.shade600),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pop(context),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      String hint,
      IconData icon, {
        bool isEmail = false,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType:
      isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
        Icon(icon, color: const Color(0xFF0D47A1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}