import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'driver_home.dart';
import 'driver_register_screen.dart';
import 'driver_forgot_password_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() =>
      _DriverLoginScreenState();
}

class _DriverLoginScreenState
    extends State<DriverLoginScreen> {
  final _driverIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  Future<void> _login() async {
    if (_driverIdController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/driver/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': _driverIdController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final result = response.body;

      // Response format:
      // SUCCESS:name:mobileNumber:companyName:managerId
      if (result.startsWith('SUCCESS')) {
        final parts = result.split(':');
        // parts[0] = SUCCESS
        // parts[1] = name
        // parts[2] = mobileNumber
        // parts[3] = companyName
        // parts[4] = managerId ← needed for depot coords
        final name =
        parts.length > 1 ? parts[1] : 'Driver';
        final managerId =
        parts.length > 4 ? parts[4] : '';

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, b) => DriverHome(
              driverIdFromLogin:
              _driverIdController.text.trim(),
              driverName: name,
              // ✅ Pass managerId so depot coords work
              managerId: managerId,
            ),
            transitionsBuilder: (_, a, b, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration:
            const Duration(milliseconds: 300),
          ),
        );
      } else if (result == 'PENDING') {
        _showError(
            'Account pending manager approval. '
                'Please wait.');
      } else {
        _showError('Invalid Driver ID or Password');
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
                      Color(0xFF1B5E20),
                      Color(0xFF388E3C)
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
                        Icons.drive_eta_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Sign in to your driver account',
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 24),
                child: Column(
                  children: [
                    // Driver ID
                    TextFormField(
                      controller: _driverIdController,
                      decoration: InputDecoration(
                        labelText: 'Driver ID',
                        hintText: 'Enter your Driver ID',
                        prefixIcon: const Icon(
                            Icons.badge_rounded,
                            color: Color(0xFF1B5E20)),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFF1B5E20)),
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

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const DriverForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                              color: Color(0xFF1B5E20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF1B5E20),
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

                    // Register link
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
                              const DriverRegisterScreen(),
                            ),
                          ),
                          child: const Text('Register',
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
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
    _driverIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}