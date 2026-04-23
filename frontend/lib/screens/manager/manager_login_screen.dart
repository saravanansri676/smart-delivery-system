import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manager_home.dart';
import 'manager_register_screen.dart';
import 'manager_forgot_password_screen.dart';
import '../../services/session_service.dart';

class ManagerLoginScreen extends StatefulWidget {
  const ManagerLoginScreen({super.key});

  @override
  State<ManagerLoginScreen> createState() =>
      _ManagerLoginScreenState();
}

class _ManagerLoginScreenState
    extends State<ManagerLoginScreen> {
  final _managerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  Future<void> _login() async {
    if (_managerIdController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/manager/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'managerId':
          _managerIdController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final result = response.body;

      // Response: SUCCESS:name:email:companyName
      if (result.startsWith('SUCCESS')) {
        final parts = result.split(':');
        final name =
        parts.length > 1 ? parts[1] : 'Manager';
        final email =
        parts.length > 2 ? parts[2] : '';
        final company =
        parts.length > 3 ? parts[3] : '';

        // ✅ Save session so app remembers on next open
        await SessionService.saveManagerSession(
          managerId: _managerIdController.text.trim(),
          managerName: name,
          managerEmail: email,
          companyName: company,
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, b) => ManagerHome(
              managerId:
              _managerIdController.text.trim(),
              managerName: name,
              managerEmail: email,
              companyName: company,
            ),
            transitionsBuilder: (_, a, b, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration:
            const Duration(milliseconds: 300),
          ),
        );
      } else if (result == 'PENDING') {
        _showError(
            'Account not verified. '
                'Please check your email for OTP.');
      } else {
        _showError('Invalid Manager ID or Password');
      }
    } catch (e) {
      _showError(
          'Connection error. Is backend running?');
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                        Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Welcome Back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        )),
                    const Text(
                        'Sign in to your manager account',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24),
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
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color:
                                Color(0xFF0D47A1))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : _login,
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
                            : const Text('Log In',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: TextStyle(
                                color:
                                Colors.grey.shade600)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const ManagerRegisterScreen(),
                            ),
                          ),
                          child: const Text('Register',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w700,
                              )),
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

  @override
  void dispose() {
    _managerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}