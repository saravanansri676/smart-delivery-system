import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'driver_login_screen.dart';
import '../../config/app_config.dart';

class DriverForgotPasswordScreen extends StatefulWidget {
  const DriverForgotPasswordScreen({super.key});

  @override
  State<DriverForgotPasswordScreen> createState() =>
      _DriverForgotPasswordScreenState();
}

class _DriverForgotPasswordScreenState
    extends State<DriverForgotPasswordScreen> {

  final _driverIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  int _currentStep = 1;
  String _securityQuestion = '';

  // ── Step 1 ──────────────────────────────────────────────
  Future<void> _fetchQuestion() async {
    if (_driverIdController.text.trim().isEmpty) {
      _showError('Please enter your Driver ID');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
        Uri.parse(
          '${AppConfig.baseUrl}/auth/driver/forgot-password/question',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': _driverIdController.text.trim(),
        }),
      )
          .timeout(AppConfig.connectTimeout);

      final result = response.body;

      if (result.startsWith('QUESTION:')) {
        setState(() {
          _securityQuestion = result.substring(9);
          _currentStep = 2;
        });
      } else if (result == 'NOT_FOUND') {
        _showError('No driver found with this ID');
      } else if (result == 'NO_SECURITY_QUESTION') {
        _showError(
          'No security question set. Contact your manager.',
        );
      } else {
        _showError('Something went wrong. Try again.');
      }
    } catch (_) {
      _showError('Connection error. Is backend running?');
    }

    setState(() => _isLoading = false);
  }

  // ── Step 2 ──────────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (_mobileController.text.trim().isEmpty ||
        _securityAnswerController.text.trim().isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (_mobileController.text.trim().length != 10) {
      _showError('Enter valid 10 digit mobile number');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (_newPasswordController.text !=
        _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
        Uri.parse(
          '${AppConfig.baseUrl}/auth/driver/forgot-password/reset',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': _driverIdController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'securityAnswer':
          _securityAnswerController.text.trim(),
          'newPassword': _newPasswordController.text,
        }),
      )
          .timeout(AppConfig.connectTimeout);

      final result = response.body;

      if (result == 'SUCCESS') {
        _showSuccessAndNavigate();
      } else if (result == 'NOT_FOUND') {
        _showError('Driver not found');
      } else if (result == 'MOBILE_MISMATCH') {
        _showError('Mobile number does not match records');
      } else if (result == 'WRONG_ANSWER') {
        _showError('Security answer is incorrect');
      } else {
        _showError('Reset failed. Try again.');
      }
    } catch (_) {
      _showError('Connection error.');
    }

    setState(() => _isLoading = false);
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: Colors.green, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Password Reset!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your password has been updated successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const DriverLoginScreen()),
                        (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _driverIdController.dispose();
    _mobileController.dispose();
    _securityAnswerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _currentStep == 1
            ? ElevatedButton(
          onPressed: _fetchQuestion,
          child: const Text('Fetch Question'),
        )
            : ElevatedButton(
          onPressed: _resetPassword,
          child: const Text('Reset Password'),
        ),
      ),
    );
  }
}