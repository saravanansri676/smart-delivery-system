import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manager_home.dart';
import 'manager_login_screen.dart';

class ManagerOTPScreen extends StatefulWidget {
  final String managerId;
  final String email;
  final String purpose; // REGISTRATION or RESET_PASSWORD
  final String? newPassword;

  const ManagerOTPScreen({
    super.key,
    required this.managerId,
    required this.email,
    required this.purpose,
    this.newPassword,
  });

  @override
  State<ManagerOTPScreen> createState() =>
      _ManagerOTPScreenState();
}

class _ManagerOTPScreenState
    extends State<ManagerOTPScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  final String baseUrl = 'http://10.0.2.2:8080';

  String get _otp =>
      _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      _showError('Please enter complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String endpoint;
      Map<String, String> body;

      if (widget.purpose == 'REGISTRATION') {
        endpoint = '$baseUrl/auth/manager/verify-registration';
        body = {
          'managerId': widget.managerId,
          'otp': _otp,
        };
      } else {
        endpoint = '$baseUrl/auth/manager/reset-password';
        body = {
          'managerId': widget.managerId,
          'otp': _otp,
          'newPassword': widget.newPassword ?? '',
        };
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final result = response.body;

      if (result.startsWith('SUCCESS')) {
        if (widget.purpose == 'REGISTRATION') {
          final parts = result.split(':');
          final name = parts.length > 1 ? parts[1] : 'Manager';
          final email = parts.length > 2 ? parts[2] : '';
          final company = parts.length > 3 ? parts[3] : '';

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => ManagerHome(
                managerId: widget.managerId,
                managerName: name,
                managerEmail: email,
                companyName: company,
              ),
            ),
                (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Password reset successful! Please login.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (_) =>
                const ManagerLoginScreen()),
                (route) => false,
          );
        }
      } else if (result == 'EXPIRED') {
        _showError('OTP expired. Please request a new one.');
      } else if (result == 'INVALID_OTP') {
        _showError('Invalid OTP. Please try again.');
      } else {
        _showError('Verification failed. Try again.');
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
                        Icons.mark_email_read_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Verify OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'OTP sent to\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // OTP boxes
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text(
                      'Enter 6-digit OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 48,
                          height: 56,
                          child: TextField(
                            controller:
                            _otpControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType:
                            TextInputType.number,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D47A1),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                borderSide: BorderSide(
                                    color: Colors
                                        .grey.shade300),
                              ),
                              focusedBorder:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                borderSide:
                                const BorderSide(
                                  color: Color(0xFF0D47A1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty &&
                                  index < 5) {
                                _focusNodes[index + 1]
                                    .requestFocus();
                              } else if (value.isEmpty &&
                                  index > 0) {
                                _focusNodes[index - 1]
                                    .requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : _verifyOTP,
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
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'OTP valid for 5 minutes',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
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