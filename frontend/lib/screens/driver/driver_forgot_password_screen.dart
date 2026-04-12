import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'driver_login_screen.dart';

class DriverForgotPasswordScreen extends StatefulWidget {
  const DriverForgotPasswordScreen({super.key});

  @override
  State<DriverForgotPasswordScreen> createState() =>
      _DriverForgotPasswordScreenState();
}

class _DriverForgotPasswordScreenState
    extends State<DriverForgotPasswordScreen> {

  // Step 1 controllers
  final _driverIdController = TextEditingController();

  // Step 2 controllers
  final _mobileController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Step tracking
  // Step 1: Enter driver ID → fetch security question
  // Step 2: Enter mobile + answer + new password → reset
  int _currentStep = 1;
  String _securityQuestion = '';

  final String baseUrl = 'http://10.0.2.2:8080';

  // ── Step 1: Fetch security question ─────────────────────
  Future<void> _fetchQuestion() async {
    if (_driverIdController.text.trim().isEmpty) {
      _showError('Please enter your Driver ID');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl/auth/driver/forgot-password/question'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': _driverIdController.text.trim(),
        }),
      );

      final result = response.body;

      if (result.startsWith('QUESTION:')) {
        final question = result.substring(9);
        setState(() {
          _securityQuestion = question;
          _currentStep = 2;
        });
      } else if (result == 'NOT_FOUND') {
        _showError('No driver found with this ID');
      } else if (result == 'NO_SECURITY_QUESTION') {
        _showError(
            'No security question set for this account. '
                'Please contact your manager.');
      } else {
        _showError('Something went wrong. Try again.');
      }
    } catch (e) {
      _showError('Connection error. Is backend running?');
    }

    setState(() => _isLoading = false);
  }

  // ── Step 2: Verify and reset password ───────────────────
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
      final response = await http.post(
        Uri.parse(
            '$baseUrl/auth/driver/forgot-password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': _driverIdController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'securityAnswer':
          _securityAnswerController.text.trim(),
          'newPassword': _newPasswordController.text,
        }),
      );

      final result = response.body;

      if (result == 'SUCCESS') {
        _showSuccessAndNavigate();
      } else if (result == 'NOT_FOUND') {
        _showError('Driver not found');
      } else if (result == 'MOBILE_MISMATCH') {
        _showError(
            'Mobile number does not match our records');
      } else if (result == 'WRONG_ANSWER') {
        _showError('Security answer is incorrect');
      } else {
        _showError('Reset failed. Try again.');
      }
    } catch (e) {
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
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Password Reset!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your password has been updated '
                    'successfully. Please login with '
                    'your new password.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Go to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    Text(
                      _currentStep == 1
                          ? 'Enter your Driver ID to begin'
                          : 'Verify your identity',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Step indicator
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        _buildStepDot(1),
                        Container(
                          width: 40,
                          height: 2,
                          color: _currentStep == 2
                              ? Colors.white
                              : Colors.white38,
                        ),
                        _buildStepDot(2),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24),
                child: _currentStep == 1
                    ? _buildStep1()
                    : _buildStep2(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step indicator dot ───────────────────────────────────
  Widget _buildStepDot(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white
            : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive
                ? const Color(0xFF1B5E20)
                : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Step 1: Enter Driver ID ──────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Enter Driver ID',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'We will fetch your security question',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _driverIdController,
          decoration: InputDecoration(
            labelText: 'Driver ID',
            hintText: 'Enter your Driver ID',
            prefixIcon: const Icon(
              Icons.badge_rounded,
              color: Color(0xFF1B5E20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _fetchQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                color: Colors.white)
                : const Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Verify identity + new password ───────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Verify Your Identity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Both mobile number and security answer '
              'must match your registered details',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 24),

        // Mobile number
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            labelText: 'Registered Mobile Number',
            hintText: '10 digit number',
            prefixIcon: const Icon(
              Icons.phone_rounded,
              color: Color(0xFF1B5E20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Security question display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
              const Color(0xFF1B5E20).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF1B5E20),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Your Security Question:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _securityQuestion,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Security answer
        TextFormField(
          controller: _securityAnswerController,
          decoration: InputDecoration(
            labelText: 'Security Answer',
            hintText: 'Answer is case-insensitive',
            prefixIcon: const Icon(
              Icons.question_answer_rounded,
              color: Color(0xFF1B5E20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // New password
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'Min 6 characters',
            prefixIcon: const Icon(
              Icons.lock_rounded,
              color: Color(0xFF1B5E20),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _obscureNew = !_obscureNew),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirm password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            hintText: 'Re-enter new password',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF1B5E20),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.grey,
              ),
              onPressed: () => setState(
                      () => _obscureConfirm = !_obscureConfirm),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Reset button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                color: Colors.white)
                : const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Back to step 1
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _currentStep = 1),
            icon: const Icon(Icons.arrow_back_rounded,
                size: 16),
            label: const Text('Change Driver ID'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1B5E20),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
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
}