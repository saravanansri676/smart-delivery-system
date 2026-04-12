import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() =>
      _DriverRegisterScreenState();
}

class _DriverRegisterScreenState
    extends State<DriverRegisterScreen> {

  // Form controllers
  final _driverIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _managerIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _requestSent = false;

  // Security question dropdown
  String _selectedQuestion =
      "What is your mother's maiden name?";

  final List<String> _securityQuestions = [
    "What is your mother's maiden name?",
    "What was the name of your first school?",
    "What is the name of your hometown?",
    "What was your childhood nickname?",
    "What is your oldest sibling's name?",
    "What was the make of your first vehicle?",
  ];

  final String baseUrl = 'http://10.0.2.2:8080';

  Future<void> _register() async {
    // Validate all fields
    if (_driverIdController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _companyController.text.isEmpty ||
        _managerIdController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _securityAnswerController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }
    if (_mobileController.text.length != 10) {
      _showError('Enter valid 10 digit mobile number');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (_securityAnswerController.text.trim().length < 2) {
      _showError('Security answer is too short');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/driver-requests/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': _driverIdController.text.trim(),
          'name': _nameController.text.trim(),
          'companyName': _companyController.text.trim(),
          'managerId': _managerIdController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'password': _passwordController.text,
          'securityQuestion': _selectedQuestion,
          'securityAnswer':
          _securityAnswerController.text.trim(),
        }),
      );

      final result = response.body;

      if (result == 'REQUEST_SENT') {
        setState(() => _requestSent = true);
      } else if (result == 'ID_EXISTS') {
        _showError('Driver ID already exists');
      } else if (result == 'MOBILE_EXISTS') {
        _showError('Mobile number already registered');
      } else if (result == 'MANAGER_NOT_FOUND') {
        _showError(
            'Manager ID not found. '
                'Please check with your manager.');
      } else if (result == 'REQUEST_PENDING') {
        _showError(
            'You already have a pending request. '
                'Please wait for manager approval.');
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

  // ── Waiting screen ───────────────────────────────────────
  Widget _buildWaitingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 64,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Request Sent!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      size: 40,
                      color: Color(0xFFE65100),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Waiting for Manager Approval',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your registration request has been '
                          'sent to your manager.\n\n'
                          'You will be able to login once '
                          'your manager approves your account.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.badge_rounded,
                              color: Color(0xFF1B5E20),
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Your Driver ID: '
                                '${_driverIdController.text.trim()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_requestSent) return _buildWaitingScreen();

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
                      'Register as a Driver',
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

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    // ── Basic Info ─────────────────────
                    _buildField(_driverIdController,
                        'Driver ID', 'Create unique ID',
                        Icons.badge_rounded),
                    const SizedBox(height: 14),
                    _buildField(_nameController,
                        'Full Name', 'Your full name',
                        Icons.person_rounded),
                    const SizedBox(height: 14),
                    _buildField(_companyController,
                        'Company Name', 'Your company',
                        Icons.business_rounded),
                    const SizedBox(height: 14),
                    _buildField(_managerIdController,
                        'Manager ID',
                        'ID of your manager',
                        Icons.admin_panel_settings_rounded),
                    const SizedBox(height: 14),

                    // Mobile
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                            10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: '10 digit number',
                        prefixIcon: const Icon(
                            Icons.phone_rounded,
                            color: Color(0xFF1B5E20)),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Min 6 characters',
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
                    const SizedBox(height: 24),

                    // ── Security Question Section ──────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20)
                            .withOpacity(0.05),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF1B5E20)
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // Section label
                          Row(
                            children: [
                              const Icon(
                                Icons.security_rounded,
                                color: Color(0xFF1B5E20),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Security Question',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight.w700,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Used to verify your identity '
                                'when you forget your password',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Question dropdown
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors
                                      .grey.shade300),
                            ),
                            child:
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedQuestion,
                                isExpanded: true,
                                icon: const Icon(
                                    Icons
                                        .arrow_drop_down_rounded,
                                    color:
                                    Color(0xFF1B5E20)),
                                items: _securityQuestions
                                    .map((q) =>
                                    DropdownMenuItem(
                                      value: q,
                                      child: Text(
                                        q,
                                        style:
                                        const TextStyle(
                                          fontSize: 13,
                                        ),
                                        overflow:
                                        TextOverflow
                                            .ellipsis,
                                      ),
                                    ))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() =>
                                    _selectedQuestion =
                                    val!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Answer field
                          TextFormField(
                            controller:
                            _securityAnswerController,
                            decoration: InputDecoration(
                              labelText: 'Your Answer',
                              hintText:
                              'Answer is case-insensitive',
                              prefixIcon: const Icon(
                                Icons.question_answer_rounded,
                                color: Color(0xFF1B5E20),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : _register,
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
                            : const Text(
                            'Send Registration Request',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: TextStyle(
                                color:
                                Colors.grey.shade600)),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pop(context),
                          child: const Text('Log In',
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

  Widget _buildField(
      TextEditingController controller,
      String label,
      String hint,
      IconData icon,
      ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
        Icon(icon, color: const Color(0xFF1B5E20)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _driverIdController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _managerIdController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }
}